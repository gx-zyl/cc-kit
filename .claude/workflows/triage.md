---
name: triage
description: 快速排查问题——同时从多个角度分析错误信息，综合定位根因
---

export const meta = {
  name: 'triage',
  description: '多角度并行排查问题，快速定位根因',
  phases: [
    { title: '信息收集', detail: '收集错误上下文' },
    { title: '多角度分析', detail: '3 个独立视角同时分析' },
    { title: '综合', detail: '汇总交叉验证后输出结论' },
  ],
}

phase('信息收集')

// 只需用户提供错误信息，不需要 schema——返回纯文本即可
const context = args?.errorMessage
  ? `错误信息：${args.errorMessage}\n请分析这个错误`
  : '请查看当前项目状态并准备分析'

// ============================================================
// 多角度并行分析（3 个独立视角互不干扰）
// ============================================================

phase('多角度分析')

// parallel 创造 barrier —— 三个 agent 同时跑，全部完成才进下一步
const analyses = await parallel([
  () => agent(
    `你是**根因分析专家**。从因果链角度分析这个问题：
    ${context}

    任务：
    1. 列出所有可能的直接原因（至少 3 个）
    2. 评估每个原因的可能性（高/中/低）
    3. 确定最可能的根因
    4. 建议验证方法

    输出结构化 JSON。`,
    {
      label: '分析:根因',
      phase: '多角度分析',
      schema: {
        type: 'object',
        properties: {
          rootCauses: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                cause: { type: 'string' },
                probability: { type: 'string', enum: ['high', 'medium', 'low'] },
                reasoning: { type: 'string' },
                verifyMethod: { type: 'string' },
              },
              required: ['cause', 'probability', 'reasoning'],
            },
          },
          mostLikely: { type: 'string' },
        },
        required: ['rootCauses', 'mostLikely'],
      },
    },
  ),

  () => agent(
    `你是**代码审查专家**。从代码角度分析这个问题：
    ${context}

    任务：
    1. 列出相关代码文件和可能出问题的位置
    2. 分析数据流：输入→处理→输出 哪个环节可能断裂
    3. 检查常见的代码级错误模式（空指针、边界条件、资源泄漏）
    4. 建议检查的具体代码位置

    输出结构化 JSON。`,
    {
      label: '分析:代码',
      phase: '多角度分析',
      schema: {
        type: 'object',
        properties: {
          suspiciousFiles: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                file: { type: 'string' },
                reason: { type: 'string' },
                checkItems: { type: 'array', items: { type: 'string' } },
              },
              required: ['file', 'reason'],
            },
          },
          dataFlowIssue: { type: 'string' },
        },
        required: ['suspiciousFiles'],
      },
    },
  ),

  () => agent(
    `你是**运维/调试专家**。从运行时的角度分析这个问题：
    ${context}

    任务：
    1. 建议排查步骤（按优先级排列）
    2. 建议添加什么日志或调试手段来定位
    3. 是否有环境/配置/依赖方面的可能性
    4. 快速修复方案（即使只是临时规避）

    输出结构化 JSON。`,
    {
      label: '分析:运维',
      phase: '多角度分析',
      schema: {
        type: 'object',
        properties: {
          steps: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                priority: { type: 'number' },
                action: { type: 'string' },
                expectedOutcome: { type: 'string' },
              },
              required: ['priority', 'action'],
            },
          },
          quickFix: { type: 'string' },
          environmentalPossibility: { type: 'string' },
        },
        required: ['steps'],
      },
    },
  ),
])

// ============================================================
// 综合阶段：汇总三方结论
// ============================================================

phase('综合')

// 过滤掉失败的 agent（返回 null）
const valid = analyses.filter(Boolean)
log(`三方分析完成，进入综合`)

// 提取共识：各个分析都指向的根因
const rootCauses = valid.flatMap(a => a.rootCauses ?? [])
const highProbCauses = rootCauses.filter(c => c.probability === 'high')

// 找出高频关键词——隐含的共识信号
log(`高可能性根因：${highProbCauses.length} 个`)

return {
  summary: {
    totalPerspectives: valid.length,
    highProbRootCauses: highProbCauses.length,
  },
  rootCauses: rootCauses.sort((a, b) => {
    const order = { high: 0, medium: 1, low: 2 }
    return (order[a.probability] ?? 9) - (order[b.probability] ?? 9)
  }),
  investigationSteps: valid.flatMap(a => a.steps ?? []).sort((a, b) => a.priority - b.priority),
  quickFix: valid.map(a => a.quickFix).filter(Boolean),
  suspiciousFiles: [...new Set(valid.flatMap(a => a.suspiciousFiles ?? []).map(f => f.file))],
}
