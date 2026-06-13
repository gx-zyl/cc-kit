# cc-kit

Claude Code 精选技能合集。**v1.7.0**

## 技能清单

### 思维与沟通

| Skill | 用途 |
|-------|------|
| diagnose | 6 阶段调试法 |
| grill-with-docs | 用文档拷打计划 |
| handoff | 交接文档 |
| grill-me | AI 拷打设计 |
| write-a-skill | 创建自定义 Skill |
| karpathy-guidelines | LLM 编码行为指南 |
| huangting-protocol | 黄庭协议 — 任务生命周期管理 |
| github-repo | GitHub 仓库创建 & CI |
| improve-codebase-architecture | 代码架构改进与重构 |
| prototype | 原型设计与探索 |
| **grow-dream** | ⭐ 对话回顾与模式沉淀 + 知识图谱入库 |

### 开发模式

| Skill | 用途 |
|-------|------|
| api-design | REST API 设计模式 |
| coding-standards | 跨项目编码规范 |
| docker-patterns | Docker/Compose 模式 |
| postgres-patterns | PostgreSQL 模式 |
| architecture-decision-records | 架构决策记录 (ADR) |

### WSL 环境工具

| Skill | 用途 |
|-------|------|
| chrome-devtools-wsl | Chrome CDP 桥接（WSL→Windows） |
| wsl-chatgpt | WSL 终端操控 ChatGPT / `/wsl-chatgpt` 命令 |
| wsl-network | WSL 网络代理 + 防火墙配置 |

> 首次使用 `chrome-devtools-wsl`：复制 `.env.example` 为 `.env` 并确认路径。

### 命令

| 命令 | 用途 |
|------|------|
| `/publish` | 一键发布新版本 |
| `/wsl-chatgpt` | WSL 终端操控 ChatGPT |

### 工作流

| Workflow | 用途 |
|----------|------|
| release | 发版工作流 |
| marketplace-doctor | 市场医生 |

> grow-dream 第⑨步自带知识图谱入库能力，无需独立 workflow。

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

## 增强工具：zoxide + fzf

zoxide 是智能 `cd`（模糊匹配 + 频率排序），fzf 是通用模糊搜索器。两者结合：`z` 直接跳，`zi` 弹出 fzf 面板交互选目录。

| 工具 | 安装 | 用途 |
|------|------|------|
| **zoxide** | `winget install ajeetdsouza.zoxide` | `z cc-kit` — 跳转到最匹配目录 |
| **fzf** | `scoop install fzf` | `zi` — 交互式选目录（zoxide 原生集成） |

**常用命令**：

| 命令 | 行为 |
|------|------|
| `z cc-kit` | 直接跳到最匹配 "cc-kit" 的目录 |
| `zi` | 弹出 fzf 面板，↑↓ 选目录，Enter 跳转 |
| `zi cc-kit` | 预过滤后再交互选择 |
| `zoxide query -l` | 列出数据库所有目录 |
| `z -` | 回退到上一个目录 |

**PowerShell profile 配置**（追加到 `$PROFILE`）：

```pwsh
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    $env:_ZO_FZF_OPTS = "--height 60% --layout reverse --border --preview 'cmd /c dir /b {} 2>nul || echo (empty)'"
    zoxide init powershell | Out-String | Invoke-Expression
}
```

首次使用：`cd` 到几个目录转转，zoxide 自动记录，之后就能 `z <关键词>` 或 `zi` 跳转了。

> 详细配置（WSL 环境、别名、更多工具链）见 `.claude/rules/wsl-cli-tools.md`。
