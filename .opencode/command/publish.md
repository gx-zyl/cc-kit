---
description: 一键发布：更新文档 → commit → tag → push
argument-hint: <version>
---

/publish $ARGUMENTS

> 前置条件：运行前确认版本号已定好。

1. 更新版本号字段：
   - `README.md` 顶部的 `**v{version}**`
   - `AGENTS.md` 的版本号
2. `git add -A && git commit -m "chore: bump version $ARGUMENTS"`
3. `git tag -a cc-kit--v$ARGUMENTS -m "cc-kit v$ARGUMENTS"`
4. `git push origin main --tags`（需代理）

> 建议：运行前 `git status` 确认工作区干净、无未跟踪文件。
