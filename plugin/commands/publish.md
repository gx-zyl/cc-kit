---
name: publish
description: 一键发布：更新文档 → commit → tag → push
---

`/publish <version>` 例如 `/publish 1.5.3`

> 前置条件：运行前确认版本号已定好。

1. 更新版本号字段：
   - `plugin/plugin.json`
   - `.claude-plugin/marketplace.json`
   - `README.md`
2. `git add -A && git commit`
3. `git tag -a cc-kit--v{version}`
4. `git push origin main --tags`（需代理）

> 建议：运行前 `git status` 确认工作区干净、无未跟踪文件。
