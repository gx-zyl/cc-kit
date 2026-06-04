# cc-kit 插件可用

## 现状

- `cc-kit` 插件已通过 GitHub marketplace + `claude plugin install` 安装并启用
- **40 个 skill**（grill-dream 已内化为 grow-dream 的子流程）+ 2 个 command（v1.5.3-dev）
- `grill-dream` 不再独立注册，追问验收逻辑整合进 grow-dream 步骤⑧
- 新增 `/w-ocean` 知识图谱体系（grow-dream 第⑨步产出）
- 新增 1 个 template：`plugin/templates/w-ocean/`（graph.json + config.yaml + README.md）
- 新增 1 个 command：`/w-ocean`（浏览/查询/遍历图谱）
- 新增 1 个 skill：`w-ocean-agent`（图谱维护：去重/合并/关联建议/健康检查）
- 新增 1 个 workflow：`w-ocean`（.yml + .md 双格式，底层引擎）
- 新增 1 个 reference：`.claude/references/skill-structure.md`（skill 文件组织规范）
- 技能路径：`plugin/plugin.json` → `./skills/{name}` → `plugin/skills/{name}/SKILL.md`

## w-ocean 架构

w-ocean 是 grow-dream 的**产物**，每次 grow-dream 运行后，在**当前项目目录**下生成/更新：

```
当前项目/
├── w-ocean/                        ← grow-dream 第⑨步生成
│   ├── graph.json                  ← 有向图数据（节点+边）
│   ├── config.yaml                 ← 配置（节点/边类型、去重规则）
│   └── README.md                   ← 使用说明
```

cc-kit 提供的是模板和工具（不直接在 cc-kit 内维护数据）：

```
cc-kit/
├── plugin/
│   ├── templates/w-ocean/          ← 初始模板
│   ├── commands/w-ocean.md         ← /w-ocean 命令
│   └── skills/w-ocean-agent/       ← 图谱维护 skill
├── .claude/workflows/w-ocean.*     ← Workflow 引擎
└── .claude/references/             ← 产出规范
```

## 关键决策

| 决策 | 说明 |
|------|------|
| 模板 vs 数据分离 | cc-kit 中只存模板和工具，w-ocean 数据在用户项目中 |
| 自动初始化 | grow-dream 第⑨步检测到无 w-ocean 时自动复制模板 |
| 节点类型可扩展 | config.yaml 可自定义节点/边类型 |
| 去重内置 | 节点按 id 去重，边按 (from, to, type) 去重 |

## 待办

- 后续新增 skill 在 `plugin/skills/` 下创建，并注册到 `plugin/plugin.json`
- 发版时同步更新 `marketplace.json` 和 `plugin.json` 的 version 字段
- 首次 grow-dream 运行后自动在用户项目生成 w-ocean/
