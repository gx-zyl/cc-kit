---
name: publish
description: 一键发布：更新文档 → commit → tag → push
---

# /publish

一键执行 cc-kit 发版流程。

## 使用

`/publish <version>` 例如 `/publish 1.5.3`

## 做什么

1. 确认版本号
2. 更新 `plugin/plugin.json` version 字段
3. 更新 `.claude-plugin/marketplace.json` version 字段
4. 更新 `README.md` 版本号
5. 更新 `docs/DONE.md`（按需）
6. `git add -A && git commit`
7. `git tag -a cc-kit--v{version}`
8. `git push origin main --tags`（需代理）

## 发布前检查

- [ ] plugin.json 和 marketplace.json 版本号一致
- [ ] STATE.md / README.md 版本号已更新
- [ ] 无遗漏文件（git status 确认）
- [ ] commit message 概括了本次变更
