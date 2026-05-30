# cc-kit

Claude Code 精选技能合集。**v1.5.0**

## 技能清单

### Matt Pocock Skill 系列

| Skill | 用途 |
|-------|------|
| diagnose | 6 阶段调试法 |
| grill-with-docs | 用文档拷打计划 |
| tdd | TDD 红-绿-重构 |
| caveman | 极简输出省 Token |
| handoff | 交接文档 |
| grill-me | AI 拷打设计 |
| write-a-skill | 创建自定义 Skill |
| grow-dream | 对话回顾与模式沉淀 |
| improve-codebase-architecture | 代码架构改进与重构 |
| prototype | 原型设计与探索 |
| triage | 问题分类与状态管理 |
| zoom-out | 宏观视角与全局上下文 |



### 通用开发模式 (ECC)

| Skill | 用途 |
|-------|------|
| coding-standards | 跨项目编码规范 |
| error-handling | 错误处理模式 |
| verification-loop | 验证循环系统 |
| architecture-decision-records | 架构决策记录 (ADR) |
| git-workflow | Git 工作流模式 |
| deployment-patterns | 部署工作流与 CI/CD |
| docker-patterns | Docker/Compose 模式 |
| database-migrations | 数据库迁移最佳实践 |
| karpathy-guidelines | LLM 编码行为指南 |
| huangting-protocol | 黄庭协议 — 任务生命周期管理 |
| github-repo | GitHub 仓库创建 & CI |

### SpringBoot / Java 后端

| Skill | 用途 |
|-------|------|
| springboot-patterns | Spring Boot 架构模式 |
| springboot-security | Spring Security 最佳实践 |
| springboot-tdd | Spring Boot TDD |
| springboot-verification | Spring Boot 验证 |
| java-coding-standards | Java 编码规范 |
| jpa-patterns | JPA/Hibernate 模式 |
| postgres-patterns | PostgreSQL 模式 |
| backend-patterns | 后端架构模式 |
| api-design | REST API 设计模式 |

### 前端 / 设计

| Skill | 用途 |
|-------|------|
| frontend-patterns | 前端开发模式 |
| vite-patterns | Vite 构建工具模式 |
| design-system | 设计系统生成与审计 |
| ui-to-vue | UI 截图转 Vue 3 组件 |

### WSL 环境工具

| Skill | 用途 |
|-------|------|
| chrome-devtools-wsl | Chrome CDP 桥接（WSL→Windows） |
| wsl-chatgpt | WSL 终端操控 ChatGPT / `/wsl-chatgpt` 命令 |
| wsl-network | WSL 网络代理 + 防火墙配置 |

> 首次使用 `chrome-devtools-wsl`：复制 `.env.example` 为 `.env` 并确认路径。

## 安装

```bash
# 首次安装
git clone https://github.com/gx-zyl/cc-kit.git ~/.claude/plugins/cc-kit

# 更新到最新版
cd ~/.claude/plugins/cc-kit && git fetch --tags origin && git checkout cc-kit--v{version}
```
或通过 `claude plugin marketplace update` 自动更新。

## 推荐终端配置

| 工具 | 用途 | 安装 |
|------|------|------|
| **Oh My Posh** | 自定义 PowerShell 提示符 | `winget install JanDeDobbeleer.OhMyPosh` |
| **Meslo Nerd Font** | 提示符图标字体 | `oh-my-posh font install Meslo`（装后终端切换为该字体） |

配置追加到 PowerShell `$PROFILE`：
```pwsh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression
```
