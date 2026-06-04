# w-ocean 图谱契约

所有 w-ocean 图谱操作（浏览/查询/遍历/追加/维护）共享的合约定义。

## 文件位置

- **路径**: 当前项目根目录下的 `w-ocean/graph.json`
- **不存在时消息**: "w-ocean 图谱不存在，请先运行 grow-dream 总结对话。"
- **初始化方式**: grow-dream 步骤⑨ 自动从插件模板复制

## 数据模型

### 顶层结构

```json
{
  "meta": { "name": "w-ocean", "nodeCount": 0, "edgeCount": 0 },
  "nodes": [],
  "edges": []
}
```

### 节点 (Node)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | ✔ | `{type}-{kebab-case-title}` |
| type | string | ✔ | skill/rule/command/agent/hook/memory/doc/concept/decision |
| title | string | ✔ | 简短名称 |
| summary | string | | 一句话总结 |
| content | string | | 文件路径或功能描述 |
| source | string | | 来源会话标识 |
| created | string | | 创建日期 |
| tags | string[] | | 关键词标签 |
| refs | string[] | | 引用的已有节点 ID |

### 边 (Edge)

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| from | string | ✔ | 源节点 ID |
| to | string | ✔ | 目标节点 ID |
| type | string | ✔ | extends/depends-on/conflicts-with/generalizes/relates-to/precedes/triggers/refines/alternative |

## 验证规则

- 节点 `id` 必须唯一
- 边的 `from` 和 `to` 必须指向存在的节点
- `refs` 中的 ID 应指向存在的节点（缺失不阻断流程，仅告警）
