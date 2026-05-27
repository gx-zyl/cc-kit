# cc-kit 插件注册完成

## 现状

- `cc-kit` 插件已通过 `extraKnownMarketplaces` + `marketplace.json` 注册到 Claude Code
- 全局 `enabledPlugins` 已启用 `cc-kit@cc-kit`，移除 `mattpocock-skills@mattpocock-skills`
- 36 个 skill 全部在 `plugin.json` 中注册，包括 `/grill-me`
- 修复 skill 路径错位：`plugin.json` 中路径从 `"./skills/"` 改为 `"../skills/"`（插件在 `.claude-plugin/` 内，skills 在项目根级）

## 链路

```
settings.json → extraKnownMarketplaces.cc-kit → D:\project\cc-kit\.claude-plugin\marketplace.json
→ plugin entry → .claude-plugin/plugin.json → skills/*
```

## 下一步

- 重启 CLI 验证 `/grill-me` 可见
- 其他插件（mattpocock-skills 等）的技能可逐步合并到 `cc-kit` 的 `plugin.json`
