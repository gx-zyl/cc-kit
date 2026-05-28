# cc-kit 插件可用

## 现状

- `cc-kit` 插件已通过 GitHub marketplace + `claude plugin install` 安装并启用
- 38 个 skill 全部加载成功（`claude plugin details` 可验证）
- 技能路径：`plugin/plugin.json` → `./skills/{name}` → `plugin/skills/{name}/skill.md`

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
