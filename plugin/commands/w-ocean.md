---
name: w-ocean
description: 浏览/查询/遍历项目知识图谱（w-ocean/）
---

# /w-ocean — 知识图谱交互命令

操作当前项目下的 `w-ocean/` 知识图谱。

## 使用

| 用法 | 说明 |
|------|------|
| `/w-ocean` | 浏览图谱概览（默认模式） |
| `/w-ocean show` | 展示全部节点 + Mermaid 图 |
| `/w-ocean show type=skill` | 按类型筛选 |
| `/w-ocean query <关键词>` | 搜索节点 |
| `/w-ocean traverse from=<节点ID> depth=<层数>` | BFS 图遍历 |

## 执行逻辑

1. **检测 w-ocean**：检查当前项目根目录是否存在 `w-ocean/graph.json`
   - 不存在 → 提示"尚未生成 w-ocean，请先运行 grow-dream 总结对话"
   - 存在 → 读取图谱数据

2. **分发子命令**：

   ### show（默认）
   读取 `w-ocean/graph.json`，输出：
   - 节点/边统计
   - 按类型分组列表
   - Mermaid 图可视化
   - 关键关联

   ### query
   在节点的 id/title/summary/tags 中搜索关键词，返回匹配结果和关联边。

   ### traverse
   从指定节点出发 BFS 遍历，输出路径树和 Mermaid 图，标记循环依赖。

3. **用户引导**：执行完后推荐下一步操作（如"尝试 `/w-ocean query 数据库` 查看相关节点"）

## 注意

- 此命令操作的是**当前项目**的 `w-ocean/`，不是 cc-kit 插件的模板
- 若 `w-ocean/graph.json` 损坏（JSON 格式错误），提示修复命令
- `graph.json` 应提交到版本控制

## 依赖

| 资源 | 用途 |
|------|------|
| `w-ocean/graph.json` | 图谱数据 |
| `.claude/workflows/w-ocean.md` | 底层 Workflow 引擎 |
