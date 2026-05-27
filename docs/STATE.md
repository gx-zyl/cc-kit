# cc-kit 插件就绪

## 现状

- `cc-kit` 插件已通过 `extraKnownMarketplaces` + `marketplace.json` 注册到 Claude Code，`enabledPlugins` 已启用
- 36 个 skill 全部在 `plugin.json` 中注册
- 已修复 skill 路径错位：`./skills/` → `../skills/`（插件在 `.claude-plugin/` 内，skills 在项目根级）
- `make-dream` skill 文件名统一为小写 `skill.md`
- **需重启 CLI 才能生效**

## 链路

```
settings.json → extraKnownMarketplaces.cc-kit → D:\project\cc-kit\.claude-plugin\marketplace.json
→ plugin entry → .claude-plugin/plugin.json → skills/*
```

## 待办

- 重启 CLI 验证 `/grill-me` 等 skill 可见
- 后续 skill 合并入 `plugin.json` 时注意路径为 `"../skills/<name>"`
