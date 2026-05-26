// Claude Workflow Tools — VS Code 插件
// 提供: {{variable}} 高亮、output→引用跳转、定义预览、诊断校验

const vscode = require('vscode')
const fs = require('fs')
const path = require('path')
const YAML = require('yaml')

/**
 * 激活插件
 */
function activate(context) {
  console.log('[Claude Workflow] 激活')

  // 注册：变量引用提供器（从 {{var}} 跳转到定义它的 output）
  context.subscriptions.push(
    vscode.languages.registerReferenceProvider(
      { language: 'yaml', pattern: '**/.claude/workflows/*.yml' },
      new VariableReferenceProvider(),
    ),
  )

  // 注册：定义提供器（Ctrl+点击 {{var}} 跳转到 output 声明行）
  context.subscriptions.push(
    vscode.languages.registerDefinitionProvider(
      { language: 'yaml', pattern: '**/.claude/workflows/*.yml' },
      new VariableDefinitionProvider(),
    ),
  )

  // 注册：悬停提示（鼠标悬停在 {{var}} 上显示来源）
  context.subscriptions.push(
    vscode.languages.registerHoverProvider(
      { language: 'yaml', pattern: '**/.claude/workflows/*.yml' },
      new VariableHoverProvider(),
    ),
  )

  // 注册：文档符号（Ctrl+Shift+O 快速跳转到步骤）
  context.subscriptions.push(
    vscode.languages.registerDocumentSymbolProvider(
      { language: 'yaml', pattern: '**/.claude/workflows/*.yml' },
      new WorkflowSymbolProvider(),
    ),
  )

  // 注册：诊断校验（output 重复、引用不存在等）
  const diagnosticCollection = vscode.languages.createDiagnosticCollection('claude-workflow')
  context.subscriptions.push(diagnosticCollection)

  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument(doc => {
      if (doc.languageId === 'yaml' && doc.uri.path.includes('.claude/workflows/')) {
        validateWorkflow(doc, diagnosticCollection)
      }
    }),
  )

  // 初始打开文件时校验
  vscode.workspace.textDocuments.forEach(doc => {
    if (doc.languageId === 'yaml' && doc.uri.path.includes('.claude/workflows/')) {
      validateWorkflow(doc, diagnosticCollection)
    }
  })
}

// ============================================================
// 构建步骤索引：解析 YAML，提取所有 steps 的 id → output 映射
// ============================================================

/**
 * 递归遍历 steps 数组，收集 { id, output, line, phase, label }
 */
function collectSteps(steps, filePath) {
  const index = []
  function walk(list, parentId) {
    if (!Array.isArray(list)) return
    for (const step of list) {
      if (!step || typeof step !== 'object') continue
      const id = step.id || parentId
      if (step.output) {
        index.push({
          variable: step.output,
          stepId: id,
          phase: step.phase,
          label: step.label,
          kind: 'output',
        })
      }
      // 递归子步骤
      if (step.parallel) walk(step.parallel, id)
      if (step.loop?.steps) walk(step.loop.steps, id)
      if (step.pipeline) {
        for (const stage of step.pipeline) {
          if (stage.agent?.output) {
            index.push({
              variable: stage.agent.output,
              stepId: `${id}.${stage.stage}`,
              kind: 'output',
            })
          }
        }
      }
    }
  }
  walk(steps)
  return index
}

/**
 * 解析 YAML 文件
 */
function parseYaml(doc) {
  try {
    const text = doc.getText()
    const parsed = YAML.parse(text)
    return parsed
  } catch {
    return null
  }
}

/**
 * 提取所有 {{variable}} 引用位置
 */
function extractReferences(doc) {
  const refs = []
  const text = doc.getText()
  const regex = /\{\{\s*([a-zA-Z_][a-zA-Z0-9_.]*)\s*\}\}/g
  let match
  while ((match = regex.exec(text)) !== null) {
    const startPos = doc.positionAt(match.index)
    const endPos = doc.positionAt(match.index + match[0].length)
    refs.push({
      variable: match[1],
      range: new vscode.Range(startPos, endPos),
    })
  }
  return refs
}

// ============================================================
// 定义提供器：{{var}} → output: var 跳转
// ============================================================

class VariableDefinitionProvider {
  provideDefinition(document, position) {
    const refs = extractReferences(document)
    // 找到鼠标位置的引用
    const hit = refs.find(r => r.range.contains(position))
    if (!hit) return null

    const yaml = parseYaml(document)
    if (!yaml?.steps) return null

    const steps = collectSteps(yaml.steps)
    const def = steps.find(s => s.variable === hit.variable && s.kind === 'output')
    if (!def) return null

    // 搜索 output 声明在文件中的位置
    const text = document.getText()
    const outputRegex = new RegExp(`output:\\s*${escapeRegex(def.variable)}\\b`)
    const outputMatch = outputRegex.exec(text)
    if (!outputMatch) return null

    const startPos = document.positionAt(outputMatch.index)
    const endPos = document.positionAt(outputMatch.index + outputMatch[0].length)
    return new vscode.Location(document.uri, new vscode.Range(startPos, endPos))
  }
}

// ============================================================
// 引用提供器：找到所有引用某变量的 {{var}}
// ============================================================

class VariableReferenceProvider {
  provideReferences(document, position) {
    const refs = extractReferences(document)
    const hit = refs.find(r => r.range.contains(position))
    if (!hit) return null

    // 返回所有引用该变量的位置（包括定义处）
    return refs
      .filter(r => r.variable === hit.variable)
      .map(r => new vscode.Location(document.uri, r.range))
  }
}

// ============================================================
// 悬停提示：显示变量来源
// ============================================================

class VariableHoverProvider {
  provideHover(document, position) {
    const refs = extractReferences(document)
    const hit = refs.find(r => r.range.contains(position))
    if (!hit) return null

    const yaml = parseYaml(document)
    if (!yaml?.steps) return null

    const steps = collectSteps(yaml.steps)
    const def = steps.find(s => s.variable === hit.variable && s.kind === 'output')
    if (!def) return null

    const label = def.label ? ` (${def.label})` : ''
    return new vscode.Hover(
      new vscode.MarkdownString(
        `**变量: \\$\\{${hit.variable}\\}**  \n` +
        `来源步骤: \`${def.stepId}\` ${label}  \n` +
        `阶段: ${def.phase || '-'}`,
      ),
    )
  }
}

// ============================================================
// 文档符号：Ctrl+Shift+O 浏览步骤结构
// ============================================================

class WorkflowSymbolProvider {
  provideDocumentSymbols(document) {
    const symbols = []
    const yaml = parseYaml(document)
    if (!yaml?.steps) return symbols

    function walk(list, container) {
      if (!Array.isArray(list)) return
      for (const step of list) {
        if (!step?.id) continue
        const label = step.label || step.id
        const kind = step.agent
          ? vscode.SymbolKind.Function
          : step.parallel
            ? vscode.SymbolKind.Array
            : step.loop
              ? vscode.SymbolKind.Event
              : vscode.SymbolKind.Null

        const sym = new vscode.DocumentSymbol(
          `${step.id} ${step.phase ? `[${step.phase}]` : ''}`,
          typeof label === 'string' ? label : step.id,
          kind,
          new vscode.Range(0, 0, 0, 0),
          new vscode.Range(0, 0, 0, 0),
        )
        symbols.push(sym)
        container?.children?.push(sym)

        if (step.parallel) walk(step.parallel, sym)
        if (step.loop?.steps) walk(step.loop.steps, sym)
      }
    }
    walk(yaml.steps)
    return symbols
  }
}

// ============================================================
// 诊断校验：output 重复、引用不存在
// ============================================================

function validateWorkflow(document, collection) {
  const diagnostics = []
  const yaml = parseYaml(document)
  if (!yaml?.steps) {
    collection.set(document.uri, diagnostics)
    return
  }

  const steps = collectSteps(yaml.steps)
  const refs = extractReferences(document)

  // 检查 1: output 重复
  const outputCount = {}
  for (const s of steps) {
    if (s.kind === 'output') {
      outputCount[s.variable] = (outputCount[s.variable] || 0) + 1
    }
  }
  for (const [varName, count] of Object.entries(outputCount)) {
    if (count > 1) {
      const text = document.getText()
      const regex = new RegExp(`output:\\s*${escapeRegex(varName)}\\b`)
      let match
      while ((match = regex.exec(text)) !== null) {
        const startPos = document.positionAt(match.index)
        const endPos = document.positionAt(match.index + match[0].length)
        diagnostics.push(
          new vscode.Diagnostic(
            new vscode.Range(startPos, endPos),
            `output 变量 "${varName}" 重复定义了 ${count} 次`,
            vscode.DiagnosticSeverity.Warning,
          ),
        )
      }
    }
  }

  // 检查 2: {{var}} 引用了不存在的 output
  const definedVars = new Set(steps.filter(s => s.kind === 'output').map(s => s.variable))
  const builtinVars = new Set(['loop.round', 'loop.index', 'loop.first', 'loop.last', 'item'])
  for (const ref of refs) {
    // 忽略带点的路径（如 item.title），只检查顶层变量
    const topVar = ref.variable.includes('.') ? ref.variable.split('.')[0] : ref.variable
    if (!definedVars.has(topVar) && !builtinVars.has(topVar)) {
      diagnostics.push(
        new vscode.Diagnostic(
          ref.range,
          `变量 "${ref.variable}" 未找到对应的 output 声明。当前已定义: ${[...definedVars].join(', ') || '(无)'}`,
          vscode.DiagnosticSeverity.Error,
        ),
      )
    }
  }

  collection.set(document.uri, diagnostics)
}

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}

// ============================================================

function deactivate() {}

module.exports = { activate, deactivate }
