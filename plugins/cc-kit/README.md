# cc-kit

Claude Code 精选技能合集。**v3.0.6**

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
| github-repo | GitHub 仓库创建 & CI |
| improve-codebase-architecture | 代码架构改进与重构 |
| prototype | 原型设计与探索 |
| **grow-dream** | ⭐ 对话回顾与模式沉淀 + 知识图谱入库 |

### 开发模式

| Skill | 用途 |
|-------|------|
| api-design | REST API 设计模式 |
| docker-patterns | Docker/Compose 模式 |
| architecture-decision-records | 架构决策记录 (ADR) |

### WSL 环境工具

| Skill | 用途 |
|-------|------|
| chrome-devtools-wsl | Chrome CDP 桥接（WSL→Windows） |
| wsl-network | WSL 网络代理 + 防火墙配置 |

> 首次使用 `chrome-devtools-wsl`：复制 `.env.example` 为 `.env` 并确认路径。

## 安装

### 推荐：Marketplace 安装（规则自动管理）

```bash
claude plugin marketplace add github:gx-zyl/cc-kit
```

Marketplace 源为 **github 类型**，插件安装和更新由 Claude Code 自动管理，`rules/` 规则文件在全局生效。

### 方式二：全局安装为插件（macOS/Linux/WSL）

```bash
git clone https://github.com/gx-zyl/cc-kit.git
ln -s "$(pwd)/cc-kit" ~/.claude/skills/cc-kit
```

### 方式三：Windows 直接克隆到插件目录

```pwsh
git clone https://github.com/gx-zyl/cc-kit.git "$env:USERPROFILE\.claude\skills\cc-kit"
```

### 方式四：项目内使用（开发/测试）

```bash
git clone https://github.com/gx-zyl/cc-kit.git
cd plugins/cc-kit && claude --plugin-dir .
```

### 手动安装后注册规则（方式二/三必做）

方式二/三为手动克隆安装，需额外执行注册使 `rules/` 目录的规则文件在所有项目中加载：

**WSL / Git Bash：**
```bash
bash ~/.claude/skills/cc-kit/tools/rules.sh install
```

**PowerShell：**
```pwsh
& "$env:USERPROFILE\.claude\skills\cc-kit\tools\rules.ps1" install
```

> 注册原理：向 `~/.claude/settings.json` 的 `instructions` 数组追加 `skills/cc-kit/rules/*.md` 条目。路径相对 `~/.claude/` 解析，指向插件内规则文件。

如需卸载规则注册：
```bash
bash ~/.claude/skills/cc-kit/tools/rules.sh uninstall      # WSL
& "$env:USERPROFILE\.claude\skills\cc-kit\tools\rules.ps1" uninstall  # PowerShell
```

> **方式四 `--plugin-dir` 无需注册**：项目级 `.claude/settings.json` 已包含 `./rules/*.md` 条目，规则自动可用。

## 架构与规则分发

### 插件层（自动加载）

| 组件 | 路径 | 说明 |
|------|------|------|
| **插件清单** | `.claude-plugin/plugin.json` | 元数据：name、version、skills 路径 |
| **15 个技能** | `skills/<name>/SKILL.md` | 由插件自动发现，无需配置 |

### 项目层（cc-kit 自身开发）

| 配置 | 路径 | 说明 |
|------|------|------|
| 项目设置 | `.claude/settings.json` | 加载 CLAUDE.md + references + rules（仅 `--plugin-dir` 模式下有效） |
| 规则 | `rules/` | WSL 工具链、代理、mise 等规则 |
| 参考 | `.claude/references/` | skill-structure、grow-dream-types |

### 根因：规则无法随插件分发

Claude Code 的 `instructions` 路径解析只扫描**两个位置**：

| 配置文件 | 用途 | 扫描范围 |
|---|---|---|
| `~/.claude/settings.json` | 全局配置 | 所有项目 |
| `<项目根>/.claude/settings.json` | 项目配置 | 仅该项目 |

**插件内的任何 `settings.json` 均不被扫描。** 所以 `rules/` 文件放在插件目录内，但无法作为 `instructions` 自动加载——Claude Code 不读插件目录下的 `settings.json`。

这是设计限制，非插件可更改。解决方案是通过安装脚本将规则路径注册到全局 `~/.claude/settings.json` 中：

```json
{
  "instructions": [
    "plugins/marketplaces/cc-kit/plugins/cc-kit/rules/*.md"
  ]
}
```

路径相对 `~/.claude/` 解析。Marketplace 安装后 `tools/rules.sh install` 自动完成此注册。

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

> 详细配置（WSL 环境、别名、更多工具链）见 `rules/wsl-cli-tools.md`。
