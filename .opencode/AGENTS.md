# cc-kit — OpenCode Skill Collection v2.0.0

Project-scope agent configuration.

## Skills

The following skills are available in `.opencode/skills/`:

| Skill | Description |
|-------|-------------|
| `api-design` | REST API 设计模式 |
| `architecture-decision-records` | ADR 格式和流程 |
| `chrome-devtools-wsl` | Chrome CDP 桥接（WSL→Windows） |
| `coding-standards` | 跨项目编码规范 |
| `diagnose` | 6 阶段调试法 |
| `docker-patterns` | Docker/Compose 模式 |
| `github-repo` | GitHub 仓库创建 & CI |
| `grill-me` | AI 拷打设计 |
| `grill-with-docs` | 用文档拷打方案 |
| `grow-dream` | 对话回顾与模式沉淀 |
| `handoff` | 交接文档 |
| `huangting-protocol` | 黄庭协议 — 任务生命周期管理 |
| `improve-codebase-architecture` | 代码架构改进 |
| `karpathy-guidelines` | LLM 编码行为指南 |
| `postgres-patterns` | PostgreSQL 模式 |
| `prototype` | 快速原型搭建 |
| `write-a-skill` | 创建自定义 Skill |
| `wsl-chatgpt` | WSL 终端操控 ChatGPT |
| `wsl-network` | WSL 网络工具集 |

## Commands

Commands are defined in `.opencode/command/`:

| Command | Description |
|---------|-------------|
| `publish <version>` | Bump version → commit → tag → push |
| `wsl-chatgpt [question]` | Send question via WSL Chrome CDP |

## Conventions

- Source of truth: `.opencode/skills/<name>/SKILL.md`
- YAML frontmatter in SKILL.md: `name` + `description` (trigger words in description)
- Commands in `.opencode/command/<name>.md`: `description` + optional `argument-hint`
- PowerShell on Windows, `pwsh` shell
