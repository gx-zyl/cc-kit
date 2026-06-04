---
name: w-ocean
description: 知识图谱工作流 — 浏览/查询/遍历 grow-dream 积累的模式，支持追加新节点
---

export const meta = {
  name: 'w-ocean',
  description: '知识图谱工作流 — 浏览/查询/遍历 grow-dream 积累的模式，支持追加新节点',
  phases: [
    { title: '加载图谱', detail: '读取 w-ocean/graph.json' },
    { title: '执行操作', detail: '按 args 执行追加/浏览/查询/遍历' },
    { title: '输出结果', detail: '展示图谱状态或确认追加' },
  ],
}

// ============================================================
// Phase 1: 加载图谱
// ============================================================

phase('加载图谱')

const GRAPH_PATH = 'w-ocean/graph.json'

// 检测 w-ocean 是否存在，读取图谱数据
const initCheck = await agent(
  `检测文件 ${GRAPH_PATH} 是否存在。` +
  `如果存在，读取并返回完整内容；如果不存在，返回 { exists: false }。`,
  {
    label: '检测:w-ocean-存在',
    phase: '加载图谱',
    schema: {
      type: 'object',
      properties: {
        exists: { type: 'boolean' },
        meta: {
          type: 'object',
          properties: {
            name: { type: 'string' },
            description: { type: 'string' },
            version: { type: 'string' },
            created: { type: 'string' },
            updated: { type: 'string' },
            nodeCount: { type: 'number' },
            edgeCount: { type: 'number' },
          },
          required: ['name', 'nodeCount', 'edgeCount'],
        },
        nodes: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              id: { type: 'string' },
              type: { type: 'string', enum: ['skill', 'rule', 'command', 'agent', 'hook', 'memory', 'doc', 'concept', 'decision'] },
              title: { type: 'string' },
              summary: { type: 'string' },
              source: { type: 'string' },
              created: { type: 'string' },
              tags: { type: 'array', items: { type: 'string' } },
              refs: { type: 'array', items: { type: 'string' } },
            },
            required: ['id', 'type', 'title'],
          },
        },
        edges: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              from: { type: 'string' },
              to: { type: 'string' },
              type: { type: 'string', enum: ['extends', 'depends-on', 'conflicts-with', 'generalizes', 'relates-to', 'precedes', 'triggers', 'refines', 'alternative'] },
            },
            required: ['from', 'to', 'type'],
          },
        },
      },
      required: ['exists'],
    },
  },
)

// 处理 w-ocean 不存在的情况
if (!initCheck.exists) {
  log('🌊 当前项目尚未初始化 w-ocean 图谱。请先运行 grow-dream 总结对话，它会自动在当前项目创建 w-ocean/。')
  return {
    status: 'not-initialized',
    message: 'w-ocean 图谱不存在，请先运行 grow-dream。',
  }
}

const graph = initCheck
log(`🌊 图谱已加载：${graph.meta.nodeCount} 个节点、${graph.meta.edgeCount} 条边`)

// ============================================================
// Phase 2: 按 args 分发操作
// ============================================================

phase('执行操作')

// ─── 无 args → 交互浏览模式 ───
if (!args || !args.action) {
  // 生成 Mermaid 图谱可视化
  if (graph.nodes.length === 0) {
    log('🌊 w-ocean 知识图谱为空。请先运行 grow-dream 总结对话并沉淀节点。')
    return {
      status: 'empty',
      message: '图谱为空，尚无节点。请先运行 grow-dream 总结对话。',
      graph,
    }
  }

  const typeCounts = {}
  for (const n of graph.nodes) {
    typeCounts[n.type] = (typeCounts[n.type] || 0) + 1
  }
  const typeSummary = Object.entries(typeCounts)
    .map(([t, c]) => `${t}: ${c}个`)
    .join('，')

  // 统计边类型分布
  const edgeTypeCounts = {}
  for (const e of graph.edges) {
    edgeTypeCounts[e.type] = (edgeTypeCounts[e.type] || 0) + 1
  }
  const edgeSummary = Object.entries(edgeTypeCounts)
    .map(([t, c]) => `${t}: ${c}条`)
    .join('，')

  log(
    `🌊 w-ocean 知识图谱概览\n` +
    `━━━━━━━━━━━━━━━━━━━━━━━\n` +
    `节点: ${graph.meta.nodeCount} 个 | 边: ${graph.meta.edgeCount} 条\n` +
    `类型分布: ${typeSummary}\n` +
    `关系分布: ${edgeSummary}\n` +
    `最新更新: ${graph.meta.updated}\n\n` +
    `可用操作: 查看全部节点 / 按类型筛选 / 关键词搜索 / 从某节点遍历`
  )

  // 用 agent 展示可交互的图谱概览
  const overview = await agent(
    `分析以下 w-ocean 图谱数据，生成一段结构化的概览报告：\n\n` +
    `节点数: ${graph.nodes.length}\n` +
    `边数: ${graph.edges.length}\n\n` +
    `全部节点:\n${graph.nodes.map(n => `- ${n.id} (${n.type}): ${n.summary || n.title}`).join('\n')}\n\n` +
    `全部边:\n${graph.edges.map(e => `- ${e.from} ─${e.type}→ ${e.to}`).join('\n')}\n\n` +
    `请输出：\n` +
    `1. 图谱总览摘要（3-5 句话）\n` +
    `2. 按类型分组的节点列表\n` +
    `3. 推荐下一步探索方向（基于当前图结构）`,
    {
      label: '展示:w-ocean-概览',
      phase: '执行操作',
    },
  )

  log(overview)

  return { status: 'shown', graph }
}

// ─── action: add — 追加节点/边（由 grow-dream 调用） ───
if (args.action === 'add') {
  const { nodes: newNodes = [], edges: newEdges = [], source } = args

  if (newNodes.length === 0 && newEdges.length === 0) {
    log('没有要追加的节点或边，跳过。')
    return { status: 'skipped', graph }
  }

  const addResult = await agent(
    `你负责将新节点和边追加到 w-ocean 知识图谱文件 ${GRAPH_PATH} 中。\n\n` +
    `当前图谱有 ${graph.nodes.length} 个节点和 ${graph.edges.length} 条边。\n\n` +
    `=== 现有节点 ID ===\n${graph.nodes.map(n => n.id).join('\n')}\n\n` +
    `=== 要追加的新节点 ===\n${JSON.stringify(newNodes, null, 2)}\n\n` +
    `=== 要追加的新边 ===\n${JSON.stringify(newEdges, null, 2)}\n\n` +
    `=== 操作规则 ===\n` +
    `1. 去重：如果新节点的 id 已存在，更新其 content/tags/refs，保留原始 created 日期\n` +
    `2. 跳过：如果新节点的内容与已有节点高度相似但 id 不同，标记为已存在并跳过\n` +
    `3. 边去重：按 (from, to, type) 三元组去重，已存在的边跳过\n` +
    `4. 自动建边：如果新节点的 refs 引用了其他节点 id，自动创建 relates-to 边\n` +
    `5. 更新 meta 统计：更新 nodeCount、edgeCount、updated 日期\n\n` +
    `执行步骤：\n` +
    `1. 先 Read ${GRAPH_PATH} 确认当前内容\n` +
    `2. 按上述规则合并新节点和边\n` +
    `3. 用 Write 写回 ${GRAPH_PATH}\n` +
    `4. 确认文件写入成功\n\n` +
    `返回追加结果统计。`,
    {
      label: '追加:w-ocean-节点',
      phase: '执行操作',
      schema: {
        type: 'object',
        properties: {
          nodesAdded: { type: 'number', description: '实际新增节点数' },
          nodesUpdated: { type: 'number', description: '更新（已存在）节点数' },
          edgesAdded: { type: 'number', description: '实际新增边数' },
          edgesSkipped: { type: 'number', description: '跳过的重复边数' },
          totalNodes: { type: 'number', description: '更新后总节点数' },
          totalEdges: { type: 'number', description: '更新后总边数' },
          source: { type: 'string', description: '来源会话标识' },
          autoEdges: { type: 'number', description: '根据 refs 自动创建的边数' },
        },
        required: ['nodesAdded', 'totalNodes', 'totalEdges'],
      },
    },
  )

  log(
    `🌊 w-ocean 追加完成\n` +
    `━━━━━━━━━━━━━━━━━━━━━━━\n` +
    `新增节点: ${addResult.nodesAdded} | 更新节点: ${addResult.nodesUpdated || 0}\n` +
    `新增边: ${addResult.edgesAdded || 0} (跳过重复: ${addResult.edgesSkipped || 0})\n` +
    `自动建边(refs): ${addResult.autoEdges || 0}\n` +
    `图谱总计: ${addResult.totalNodes} 节点 / ${addResult.totalEdges} 条边\n` +
    `来源: ${addResult.source || source || 'unknown'}`
  )

  return { status: 'added', result: addResult }
}

// ─── action: show — 浏览图谱（可按 type 筛选） ───
if (args.action === 'show') {
  const filtered = args.type
    ? graph.nodes.filter(n => n.type === args.type)
    : graph.nodes

  if (filtered.length === 0) {
    log(args.type ? `没有 ${args.type} 类型的节点` : '图谱为空')
    return { status: 'empty', filter: args.type }
  }

  // 生成 Mermaid 图
  const mermaidLines = ['```mermaid', 'graph LR']
  for (const n of filtered) {
    const label = `${n.title}\\n(${n.type})`
    // sanitize id for mermaid
    const safeId = n.id.replace(/[^a-zA-Z0-9]/g, '_')
    mermaidLines.push(`  ${safeId}["${label}"]`)
  }
  for (const e of graph.edges) {
    const fromSafe = e.from.replace(/[^a-zA-Z0-9]/g, '_')
    const toSafe = e.to.replace(/[^a-zA-Z0-9]/g, '_')
    const fromExists = filtered.some(n => n.id === e.from)
    const toExists = filtered.some(n => n.id === e.to)
    if (fromExists && toExists) {
      mermaidLines.push(`  ${fromSafe} --${e.type}--> ${toSafe}`)
    }
  }
  mermaidLines.push('```')

  log(
    `📊 w-ocean 图谱浏览${args.type ? ` (筛选: ${args.type})` : ''}\n` +
    `━━━━━━━━━━━━━━━━━━━━━━━\n` +
    `显示 ${filtered.length}/${graph.nodes.length} 个节点\n\n` +
    mermaidLines.join('\n')
  )

  // 用 agent 做结构化呈现
  const detail = await agent(
    `以下是 w-ocean 知识图谱的节点列表（${args.type ? `筛选类型=${args.type}` : '全部'}）：\n\n` +
    filtered.map(n =>
      `- **${n.id}** (${n.type})\n  ${n.summary || n.title}\n  标签: ${(n.tags || []).join(', ') || '无'}\n  来源: ${n.source || '未知'}\n  创建: ${n.created}`
    ).join('\n\n') +
    `\n\n请以清晰的结构展示这些节点，按类型分组。`,
    {
      label: `展示:节点列表${args.type ? `-${args.type}` : ''}`,
      phase: '执行操作',
    },
  )

  log(detail)
  return { status: 'shown', nodes: filtered }
}

// ─── action: query — 关键词搜索 ───
if (args.action === 'query') {
  const keyword = (args.keyword || '').toLowerCase()
  if (!keyword) {
    log('请输入搜索关键词：args.keyword')
    return { status: 'error', message: '缺少 keyword' }
  }

  const matched = graph.nodes.filter(n =>
    n.id.toLowerCase().includes(keyword) ||
    n.title.toLowerCase().includes(keyword) ||
    (n.summary || '').toLowerCase().includes(keyword) ||
    (n.tags || []).some(t => t.toLowerCase().includes(keyword))
  )

  if (matched.length === 0) {
    log(`🔍 未找到匹配 "${keyword}" 的节点`)
    return { status: 'not-found', keyword }
  }

  // 找出匹配节点的关联边
  const matchedIds = new Set(matched.map(n => n.id))
  const relatedEdges = graph.edges.filter(e =>
    matchedIds.has(e.from) || matchedIds.has(e.to)
  )

  log(
    `🔍 搜索 "${keyword}"：找到 ${matched.length} 个节点、${relatedEdges.length} 条关联边\n` +
    matched.map(n => `- ${n.id} (${n.type}): ${n.summary || n.title}`).join('\n')
  )

  if (relatedEdges.length > 0) {
    log('关联关系：\n' + relatedEdges.map(e => `- ${e.from} ─${e.type}→ ${e.to}`).join('\n'))
  }

  return { status: 'found', keyword, nodes: matched, edges: relatedEdges }
}

// ─── action: traverse — 图遍历 ───
if (args.action === 'traverse') {
  const startId = args.from
  const maxDepth = args.depth || 2

  if (!startId) {
    log('请指定起始节点：args.from')
    return { status: 'error', message: '缺少 from' }
  }

  const startNode = graph.nodes.find(n => n.id === startId)
  if (!startNode) {
    log(`节点 "${startId}" 不存在`)
    return { status: 'not-found', nodeId: startId }
  }

  const traverseResult = await agent(
    `对 w-ocean 图谱进行从 "${startId}" 出发的 BFS 遍历，最大深度 ${maxDepth} 层。\n\n` +
    `完整图谱:\n节点:\n${graph.nodes.map(n => `- ${n.id} (${n.type}): ${n.summary || n.title}`).join('\n')}\n\n` +
    `边:\n${graph.edges.map(e => `- ${e.from} ─${e.type}→ ${e.to}`).join('\n')}\n\n` +
    `请输出遍历结果：\n` +
    `1. 从 ${startId} 出发的路径树\n` +
    `2. 每层的节点和边\n` +
    `3. 如果存在循环（有向环），标记出来\n` +
    `4. Mermaid graph 可视化\n` +
    `5. 发现模式总结（如"A→B→C 形成工具链"等）`,
    {
      label: `遍历:从-${startId}-深度${maxDepth}`,
      phase: '执行操作',
    },
  )

  log(traverseResult)
  return { status: 'traversed', from: startId, depth: maxDepth }
}

// ─── 未知 action ───
log(`未知操作: ${args.action}。支持的操作: add, show, query, traverse`)
return { status: 'unknown-action', action: args.action }
