---
name: cc-kit
description: cc-kit 插件元技能。描述 cc-kit 的能力边界：15 个技能覆盖调试(grill-with-docs/diagnose)、架构审查(improve-codebase-architecture)、API设计(api-design)、Docker(docker-patterns)、WSL环境工具(chrome-devtools-wsl/wsl-network)、对话模式沉淀(grow-dream)、设计拷打(grill-me)、交接文档(handoff)等。用户问"cc-kit 有什么"、"插件能力"时触发。
---

# cc-kit 插件

cc-kit 是一个 Claude Code 插件合集，提供 15 个精选 AI 技能。

## 技能目录

| 类别 | 技能 |
|------|------|
| 调试 | diagnose, grill-with-docs |
| 架构 | improve-codebase-architecture, architecture-decision-records |
| 设计 | api-design, grill-me, prototype |
| 数据 | docker-patterns |
| 沉淀 | grow-dream, handoff, write-a-skill |
| WSL | chrome-devtools-wsl, wsl-network |
| 规范 | karpathy-guidelines |
| 工具 | github-repo |

## 全局规则

- 项目使用 PowerShell（`pwsh`），非 bash
- 技能描述中的触发词决定了 Claude 何时加载该技能
- grow-dream 第⑨步自动将采纳的改进沉淀到 w-ocean 知识图谱

## 参考文档

随插件分发的规则/参考文件，位于插件根目录 `rules/`：

| 路径 | 文件 | 用途 |
|------|------|------|
| `../../rules/` | `wsl-cli-tools.md` | WSL 现代 CLI 工具链映射表 |
| `../../rules/` | `proxy-management.md` | 代理管理与 marketplace 操作指南 |
