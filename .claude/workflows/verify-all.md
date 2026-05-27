---
name: verify-all
description: 运行测试/类型检查/构建，逐项修复直到全部通过
---

export const meta = {
  name: 'verify-all',
  description: '循环运行检查→修复→再检查，直到全部通过或达到上限',
  phases: [
    { title: '验证', detail: '运行检查命令' },
    { title: '修复', detail: '修复发现的失败' },
  ],
}

phase('验证')

let results = null
const MAX_ROUNDS = 3

for (let round = 1; round <= MAX_ROUNDS; round++) {
  log(`===== 第 ${round}/${MAX_ROUNDS} 轮 =====`)

  // 并行运行三种检查
  const checks = await parallel([
    () => agent(
      '运行项目类型检查（如 tsc --noEmit）。如果失败，输出所有类型错误的 JSON 列表：' +
      '{ "passed": boolean, "errors": [{ "file", "line", "message" }] }',
      { label: '类型检查', phase: '验证', schema: { type: 'object', properties: {
        passed: { type: 'boolean' },
        errors: { type: 'array', items: { type: 'object', properties: {
          file: { type: 'string' }, line: { type: 'number' }, message: { type: 'string' },
        }, required: ['file', 'message'] } },
      }, required: ['passed'] } },
    ),
    () => agent(
      '运行测试（jest 或 vitest run）。输出 JSON：' +
      '{ "passed": boolean, "failed": number, "failures": [{ "test", "file", "message" }] }',
      { label: '单元测试', phase: '验证', schema: { type: 'object', properties: {
        passed: { type: 'boolean' },
        failed: { type: 'number' },
        failures: { type: 'array', items: { type: 'object', properties: {
          test: { type: 'string' }, file: { type: 'string' }, message: { type: 'string' },
        }, required: ['test', 'message'] } },
      }, required: ['passed', 'failed'] } },
    ),
    ...(round === 1
      ? [() => agent(
          '运行构建检查（npm run build 或 vite build）。输出 JSON：' +
          '{ "passed": boolean, "errors": [{ "message" }] }',
          { label: '构建检查', phase: '验证', schema: { type: 'object', properties: {
            passed: { type: 'boolean' },
            errors: { type: 'array', items: { type: 'object', properties: {
              message: { type: 'string' },
            }, required: ['message'] } },
          }, required: ['passed'] } },
        )]
      : []),
  ])

  // 提取失败项
  const failures = []
  if (checks[0] && !checks[0].passed) failures.push(...checks[0].errors.map(e => ({ ...e, type: 'type' })))
  if (checks[1] && !checks[1].passed) failures.push(...checks[1].failures.map(f => ({ ...f, type: 'test' })))
  if (checks[2] && !checks[2].passed) failures.push(...checks[2].errors.map(e => ({ ...e, type: 'build' })))

  const allPassed = checks.every(c => c?.passed)

  if (allPassed) {
    log('🎉 全部通过！')
    results = { passed: true, rounds: round, failures: [] }
    break
  }

  log(`发现 ${failures.length} 个失败项`)

  if (round < MAX_ROUNDS) {
    phase('修复')

    // 按类型分组派 agent 修复
    const typeFailures = failures.filter(f => f.type === 'type')
    const testFailures = failures.filter(f => f.type === 'test')
    const buildFailures = failures.filter(f => f.type === 'build')

    const fixers = []
    if (typeFailures.length > 0) {
      fixers.push(() => agent(
        `修复以下类型错误：\n${typeFailures.map(f => `- ${f.file}:${f.line} ${f.message}`).join('\n')}\n\n修复后运行 tsc --noEmit 验证。`,
        { label: '修复:类型', phase: '修复' },
      ))
    }
    if (testFailures.length > 0) {
      fixers.push(() => agent(
        `修复以下测试失败：\n${testFailures.map(f => `- ${f.test} (${f.file}): ${f.message}`).join('\n')}\n\n修复后运行对应测试验证。`,
        { label: '修复:测试', phase: '修复' },
      ))
    }
    if (buildFailures.length > 0) {
      fixers.push(() => agent(
        `修复以下构建错误：\n${buildFailures.map(f => `- ${f.message}`).join('\n')}\n\n修复后重新构建验证。`,
        { label: '修复:构建', phase: '修复' },
      ))
    }

    if (fixers.length > 0) {
      await parallel(fixers)
    }

    phase('验证') // 下一轮验证
  } else {
    log('达到最大轮次，仍有失败项')
    results = { passed: false, rounds: round, failures }
  }
}

return results ?? { passed: false, rounds: MAX_ROUNDS, failures: [] }
