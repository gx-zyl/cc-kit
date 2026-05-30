# cc-kit 插件可用

## 现状

- `cc-kit` 插件已通过 GitHub marketplace + `claude plugin install` 安装并启用
- **39 个 skill** + 1 个 command（v1.5.0）
- 新增 3 个 WSL 工具 skill：`wsl-chatgpt`、`wsl-network`、`chrome-devtools-wsl`
- 新增 3 个 WSL 规则：`wsl-env-audit`、`wsl-cli-tools`、`mise-omz-loading-order`
- 技能路径：`plugin/plugin.json` → `./skills/{name}` → `plugin/skills/{name}/SKILL.md`
- 参数配置：`chrome-devtools-wsl/.env.example` → 复制为 `.env` 后修改

## 链路

```
settings.json → extraKnownMarketplaces.cc-kit → GitHub (gx-zyl/cc-kit)
→ git clone → .claude-plugin/marketplace.json
→ source: ./plugin → plugin/plugin.json → plugin/skills/*
```

## 关键决策

| 决策 | 说明 |
|------|------|
| 市场源 | 用 `git` 而非 `directory`（后者 v2.1.150 不支持 `plugin install`） |
| 插件目录 | `plugin/` 子目录（匹配官方约定，source 以市场根为基准） |
| 技能位置 | `plugin/skills/`（不能在插件目录外或用 symlink） |

## 待办

- 后续新增 skill 在 `plugin/skills/` 下创建，并注册到 `plugin/plugin.json`
- 发版时同步更新 `marketplace.json` 和 `plugin.json` 的 version 字段
