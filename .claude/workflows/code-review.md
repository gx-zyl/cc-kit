---
name: code-review
description: 审查当前分支的变更，从多个维度并行分析并交叉验证，确保结果可靠
---

export const meta = {
  name: 'code-review',
  description: '审查当前分支变更，按维度并行分析并交叉验证',
  phases: [
    { title: '扫描变更', detail: 'git diff 获取变更文件列表' },
    { title: '多维度审查', detail: '并行派 agent 按维度审查' },
    { title: '对抗性验证', detail: '每条发现由 3 个独立 agent 尝试证伪' },
    { title: '综合报告', detail: '汇总可信结果输出报告' },
  ],
}

// ============================================================
// Phase 1: 扫描变更
// ============================================================

phase('扫描变更')

// 先用一个 agent 做 git diff 分析
const diffAnalysis = await agent(
  '运行 git diff main...HEAD --stat 获取变更文件列表，然后对每个文件运行 git diff main...HEAD -- <file> 获取详细 diff。' +
  '输出 JSON：{ files: [{ path, status, additions, deletions, diff }], totalChanges: number }',
  {
    label: '扫描:git-diff',
    phase: '扫描变更',
    schema: {
      type: 'object',
      properties: {
        files: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              path: { type: 'string' },
              status: { type: 'string', enum: ['added', 'modified', 'deleted', 'renamed'] },
              additions: { type: 'number' },
              deletions: { type: 'number' },
              diff: { type: 'string' },
            },
            required: ['path', 'status', 'diff'],
          },
        },
        totalChanges: { type: 'number' },
      },
      required: ['files', 'totalChanges'],
    },
  },
)

log(`发现 ${diffAnalysis.files.length} 个变更文件，共 ${diffAnalysis.totalChanges} 处变更`)

// 如果没变更就直接结束
if (diffAnalysis.files.length === 0) {
  log('没有检测到变更，跳过审查')
  return { summary: '无变更', findings: [] }
}

// ============================================================
// Phase 2: 多维度并行审查
// ============================================================

phase('多维度审查')

// 将 files 按路径分组，避免单个 agent 处理太多文件
const fileGroups = []
const groupSize = Math.max(1, Math.ceil(diffAnalysis.files.length / 3))
for (let i = 0; i < diffAnalysis.files.length; i += groupSize) {
  fileGroups.push(diffAnalysis.files.slice(i, i + groupSize))
}

// 并行审查各维度 —— 这里用 pipeline 让每个维度的审查独立流向后继阶段
const allFindings = await pipeline(
  // 维度列表
  [
    { dimension: 'bug', prompt: '找出所有可能的逻辑错误、边界条件遗漏、空指针风险、并发问题。关注代码的正确性而非风格。' },
    { dimension: 'security', prompt: '找出所有安全风险：注入、XSS、CSRF、认证绕过、敏感信息泄露、权限检查缺失。' },
    { dimension: 'performance', prompt: '找出性能问题：不必要的数据库查询、N+1 问题、内存泄漏、大对象重复创建、同步阻塞。' },
    { dimension: 'architecture', prompt: '评估架构合规性：是否遵循项目分层、有无循环依赖、接口抽象是否合理、关注点分离。' },
  ],

  // Stage 1: 按维度审查各自文件组
  async dim => {
    const results = await parallel(
      fileGroups.map((group, i) => () =>
        agent(
          `你是一名 ${dim.dimension} 专家。审查以下代码变更，只关注 ${dim.dimension} 问题。\n\n` +
          `文件列表：\n${group.map(f => `- ${f.path} (${f.status}, +${f.additions}/-${f.deletions})`).join('\n')}\n\n` +
          `完整 diff：\n${group.map(f => `\n### ${f.path}\n${'```'}diff\n${f.diff}\n${'```'}`).join('\n')}\n\n` +
          `每个发现必须包含：文件路径、行号范围、严重程度(high/medium/low)、问题描述、修复建议。` +
          `${dim.prompt}`,
          {
            label: `审查:${dim.dimension}-组${i + 1}`,
            phase: '多维度审查',
            schema: {
              type: 'object',
              properties: {
                findings: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      file: { type: 'string' },
                      lines: { type: 'string' },
                      severity: { type: 'string', enum: ['high', 'medium', 'low'] },
                      title: { type: 'string' },
                      description: { type: 'string' },
                      suggestion: { type: 'string' },
                    },
                    required: ['file', 'severity', 'title', 'description'],
                  },
                },
              },
              required: ['findings'],
            },
          },
        ),
      ),
    )
    return {
      dimension: dim.dimension,
      findings: results.flatMap(r => r?.findings ?? []),
    }
  },
)

// 汇总所有发现的 flat 列表
const rawFindings = allFindings.flatMap(d => d.findings.map(f => ({ ...f, dimension: d.dimension })))
log(`共发现 ${rawFindings.length} 条潜在问题（${rawFindings.filter(f => f.severity === 'high').length} 条严重）`)

if (rawFindings.length === 0) {
  log('没有发现任何问题')
  return { summary: '未发现问题', findings: [] }
}

// ============================================================
// Phase 3: 对抗性验证（3 票证伪制）
// ============================================================

phase('对抗性验证')

// 只验证 high + medium 级别的问题
const toVerify = rawFindings.filter(f => f.severity !== 'low')
log(`对 ${toVerify.length} 条 medium+ 问题进行对抗性验证（每条 3 票）`)

const verdicts = await parallel(
  toVerify.map(f => () =>
    parallel(
      Array.from({ length: 3 }, (_, i) => () =>
        agent(
          `你是一名挑剔的代码审查员。你的任务是 **证伪** 以下发现，而不是确认它。\n\n` +
          `发现：${f.title}\n` +
          `文件：${f.file}:${f.lines}\n` +
          `描述：${f.description}\n\n` +
          `请从以下角度尝试反驳：\n` +
          `1. 这是误报吗？代码实际上做了正确的事情？\n` +
          `2. 影响被夸大了吗？这是一个边缘情况不太可能发生？\n` +
          `3. 这是故意设计/已知的技术债务？\n\n` +
          `只有当你无法反驳时才判定为真实问题。不确定 = 证伪。`,
          {
            label: `验证:${f.file}-${i + 1}`,
            phase: '对抗性验证',
            schema: {
              type: 'object',
              properties: {
                refuted: { type: 'boolean' },
                reason: { type: 'string' },
                isReal: { type: 'boolean' },
              },
              required: ['refuted', 'reason', 'isReal'],
            },
          },
        ),
      ),
    ),
  ),
)

// 幸存规则：至少 2/3 投通过
const confirmedFindings = toVerify.filter((_, i) => {
  const votes = verdicts[i]
  if (!votes) return false
  const realVotes = votes.filter(v => v?.isReal)
  return realVotes.length >= 2
})

// 加上未验证的 low 级别问题
const lowFindings = rawFindings.filter(f => f.severity === 'low')
const allConfirmed = [...confirmedFindings, ...lowFindings]

log(`验证通过：${confirmedFindings.length}/${toVerify.length} 条确认`)

// ============================================================
// Phase 4: 综合报告
// ============================================================

phase('综合报告')

return {
  summary: {
    totalFiles: diffAnalysis.files.length,
    totalChanges: diffAnalysis.totalChanges,
    totalFindings: rawFindings.length,
    confirmedFindings: allConfirmed.length,
    bySeverity: {
      high: allConfirmed.filter(f => f.severity === 'high').length,
      medium: allConfirmed.filter(f => f.severity === 'medium').length,
      low: allConfirmed.filter(f => f.severity === 'low').length,
    },
  },
  findings: allConfirmed.sort((a, b) => {
    const order = { high: 0, medium: 1, low: 2 }
    return (order[a.severity] ?? 9) - (order[b.severity] ?? 9)
  }),
}
