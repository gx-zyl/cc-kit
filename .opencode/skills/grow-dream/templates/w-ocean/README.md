# w-ocean — 知识海洋

你的项目知识图谱。由 `grow-dream` 自动生成和维护。

## 这是什么

每次运行 `grow-dream` 总结对话后，发现的可复用模式（skill/rule/command/agent/hook/memory/doc）会被格式化为**节点**，节点间的关联被记录为**边**，构成一个有向图知识图谱。

## 使用方式

```bash
# 浏览全图
/w-ocean show

# 按类型筛选
/w-ocean show type=skill

# 搜索关键词
/w-ocean query "数据库"

# 从某节点出发遍历（深度2层）
/w-ocean traverse from=rule-coding-standards depth=2

# 图谱健康检查
/w-ocean-agent health
```

## 目录结构

```
w-ocean/
├── graph.json      # 图谱数据（节点 + 边）
├── config.yaml     # 配置（节点/边类型、去重规则）
└── README.md       # 本文件
```

## 节点 ID 规则

```
{type}-{kebab-case-title}
```

例：`skill-grill-dream`, `rule-coding-standards`, `memory-user-preference`

## 最佳实践

1. **定期 grow-dream** — 每次有重要对话后运行，沉淀新发现
2. **维护图谱健康** — 每月运行 `w-ocean-agent maintain` 去重/合并
3. **关联已有节点** — 在 grow-dream 总结时通过 `refs` 引用已有节点
4. **扩展节点类型** — 编辑 `config.yaml` 添加新类型

## 数据安全

`graph.json` 应提交到版本控制（团队共享知识）。
`node_modules/`、`.git/` 等已默认排除。
