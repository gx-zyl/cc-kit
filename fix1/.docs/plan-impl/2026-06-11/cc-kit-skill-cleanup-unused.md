# cc-kit 清理无关 Skill

## 问题

Claude Code 中积累了 40+ 个永远用不上的 skill：

- **vercel** 全家桶 29 个 — 用户是 Spring Boot 后端，不碰 Vercel/Next.js
- **understand-anything** 8 个 — 不做代码库知识图谱分析
- **design-system / triage / zoom-out** 3 个 — 低频且非必需

这些无用 skill 污染了 `/` 命令补全和对话上下文，增加认知负担。

## 方法

```
卸载插件 + 清理技能注册 + 删除文件 + 发版
```

## 链路矩阵流程

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Audit       │────>│  Uninstall   │────>│  Remove from │────>│  Publish     │
│  claude      │     │  plugin      │     │  plugin.json │     │  v1.5.5      │
│  plugin list │     │  vercel      │     │  & delete    │     │  push to     │
│              │     │  understand  │     │  skill files │     │  GitHub      │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
       │                    │                     │                    │
       ▼                    ▼                     ▼                    ▼
  发现 3 个插件         -29 skill           -3 skill            见证：只剩
  40+ 无用 skill       -8 skill            文件已清理            cc-kit 1 个
```

**消费方：** `cc-kit` 插件维护者（你），每次 `/` 调 skill 时不再看到无关命令。

## 卡通

```
                      ╔══════════════════╗
             ═══════  ║   cc-kit 1.5.4   ║
            ╱         ╚══════════════════╝
          ╱           ┌──────────────┐
   vercel ════════════│  29 skills   │  ❌
   plugin             └──────────────┘
                      ┌──────────────┐
   understand ════════│  8 skills    │  ❌
   plugin             └──────────────┘
                      ┌──────────────┐
   cc-kit   ══════════│  3 low-freq  │  ❌ → 🗑️
                      └──────────────┘
          ╲
           ╲          ╔══════════════════╗
             ═══════  ║   cc-kit 1.5.5   ║  ✅ 只剩 39 个实用 skill
             (clean)  ╚══════════════════╝
```

## 解读步骤

1. **Audit** — `claude plugin list` 发现 3 个已启用插件，其中 vercel 和 understand-anything 跟用户技术栈（Spring Boot / WSL / Vue）完全无关
2. **Uninstall** — `claude plugin uninstall` 卸载两个外网插件，除去 37 个无用 skill
3. **Prune** — 从 `plugin/plugin.json` 的 `skills` 数组去掉 3 条注册，并删除对应的 skill 目录及文件
4. **Publish** — 更新 `plugin.json` / `marketplace.json` / `README.md` 版本号 → commit → tag `cc-kit--v1.5.5` → push

## 验证

```bash
claude plugin list
# → 只剩 cc-kit@cc-kit ✔ enabled
# vercel / understand-anything 已消失
```

## 文件变更

| 文件 | 操作 |
|------|------|
| `plugin/plugin.json` | 移除 3 条 skill 注册 + 版本号 1.5.4→1.5.5 |
| `.claude-plugin/marketplace.json` | 版本号 1.5.4→1.5.5 |
| `README.md` | 版本号 1.5.4→1.5.5 |
| `plugin/skills/design-system/SKILL.md` | 删除 |
| `plugin/skills/triage/SKILL.md` + 子文件 | 删除 |
| `plugin/skills/zoom-out/SKILL.md` | 删除 |
