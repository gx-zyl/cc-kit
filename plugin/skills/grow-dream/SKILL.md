---
name: grow-dream
description: 回顾本次对话，分析对 skill / rule / agent / hook / workflow / CLAUDE.md / AGENTS.md / 项目文档 是否有改进空间，输出改进建议并可选择直接产出改进文件。用户说"改进"、"沉淀"、"提炼规则"、"这个经历能沉淀什么"、"有没有可以提炼成规则的模式"、"造梦"、"总结对话"、"提炼经验"、"固化模式"、"make dream"时触发。
---

# grow-dream — 对话回顾与能力成长

回顾当前对话，识别可沉淀的模式，输出改进建议。

## 回顾维度

| 维度 | 检查内容 |
|------|---------|
| **skill** | 对话中暴露了哪些 skill 的缺失、错误或不足？触发关键词是否需要更新？ |
| **command** | 是否有重复 ≥2 次的确定性操作序列？能否用一条命令替代手工步骤？触发关键词是否需要更新？ |
| **rule** | 对话中暴露出哪些新的规则需要？现有规则是否有错误或需要增强？ |
| **agent** | 是否有适合做成专用 agent 的重复操作模式？ |
| **hook** | 是否有适合做成 hook 的自动化行为（如每次 push 前的检查）？ |
| **workflow** | 是否有适合做成 workflow 的多步骤编排模式？注：指 Claude Code CLI workflow，格式为 `.md` + YAML frontmatter。 |
| **CLAUDE.md** | 是否存在？内容与项目实际架构是否一致？是否有过期路径/命令/约定？与 `rules/` 文件有无重复或冲突？是否需要补充环境、命令、目录约定？ |
| **AGENTS.md / agents/** | 是否存在？定义的 agent 角色是否匹配项目需求？有定义无对应文件？是否记录了使用场景与边界？ |
| **项目文档** | `docs/` 各文件（STATE / WARN / DONE / HISTORY）是否遵循行数约束？内容是否反映最新状态？文档间有无矛盾？是否有已过期但未归档的内容？ |
| **[交叉检查] 冲突与矛盾** | CLAUDE.md / AGENTS.md / docs / skill 定义 / rule 文件 / agent 角色 / hook 脚本 / workflow 编排之间是否存在相互矛盾的描述？同一概念在不同文件中的用语是否统一？AI 的反馈是否与项目文件记录的一致？用户纠正过的行为是否在对应文件中已更新？ |

## 执行步骤

0. **确定输入源** — 选择分析范围：
   - 本次对话（默认）
   - 指定对话日志（路径）
   - git log / commit message
   - 特定文件或目录的修改历史

1. 浏览对话/输入源，识别重复发生的模式、错误、或显式纠正
2. 扫描项目 CLAUDE.md、AGENTS.md、`.claude/agents/`、`docs/` 文件，与发现的实际行为对照：
   - **CLAUDE.md**：记录的路径/命令/约定是否与实际使用一致？是否有遗漏的关键约定？
   - **AGENTS.md/agents/**：定义的 agent 是否被实际使用？实际使用的 agent 是否被记录？
   - **项目文档**：STATE/DONE/WARN/HISTORY 是否反映了最近的变更？行数是否超限？
3. **交叉检查**：逐对比对各文件对同一概念的描述是否一致；检查用户曾纠正过的行为是否已在对应文件中更新；确认 AI 的反馈与项目文件无矛盾
4. **提炼分类** — 按频次和性质归类：
   - 重复 ≥2 次的确定性操作 → command
   - 特定场景的解题套路（需判断分支）→ skill
   - 跨项目的通用行为约束 → rule
   - 多步骤编排、步骤间有数据传递 → workflow（Claude Code CLI 格式：`.md` + YAML frontmatter）
   - 需独立判断、持续运行的有限角色 → agent
   - 特定 git/claude 事件触发的自动化 → hook
   - 项目根文档缺失或不一致 → CLAUDE.md / AGENTS.md
   - 项目文档超限或过期 → STATE / DONE / WARN / HISTORY
5. 对每个维度逐一判断：是否有改进空间？
6. 输出结构化建议：改进什么文件、怎么改、为什么
7. 对于需要用户决策的改进，提供选项
8. **可选执行**：询问用户是否直接产出改进文件。若确认，按执行模式生成对应文件，并应用输出检查

## 输出格式

```
## 改进建议

### skill
- [skill-name]: 建议 + 原因

### command
- [command-name]: 建议 + 原因

### rule
- [rule-file]: 建议 + 原因

### agent
- [agent-name]: 建议 + 原因

### hook
- [hook-description]: 建议 + 原因

### workflow
- [workflow-name]: 建议 + 原因

### CLAUDE.md
- [CLAUDE.md / 缺失]: 建议 + 原因

### AGENTS.md
- [AGENTS.md / agents/ 目录]: 建议 + 原因

### 项目文档
- [docs/STATE.md / DONE.md / WARN.md / HISTORY.md]: 建议 + 原因

### 交叉检查：冲突与矛盾
- [文件 A vs 文件 B / AI 反馈 vs 文件]: 矛盾点 + 建议统一方向
```

## 执行模式（可选）

用户确认后，直接产出改进文件。每种改进类型对应固定路径和判定条件：

| 产出类型 | 目标路径 | 适用条件 |
|---------|---------|---------|
| **skill** | `plugin/skills/<name>/SKILL.md` | 有判断分支、需要上下文理解的场景化能力 |
| **command** | `plugin/skills/<name>/SKILL.md` | 步骤固定、无需 AI 判断的确定性操作 |
| **rule** | `.claude/rules/<name>.md` | 跨项目的通用行为约束 |
| **workflow** | `.claude/workflows/<name>.md`（YAML frontmatter） | 多步骤编排、步骤间有数据传递；Claude Code CLI workflow 格式 |
| **agent** | `.claude/agents/<name>.md` | 持续运行、有决策自主权、面向特定领域 |
| **hook** | `.claude/hook.<event>.sh` | 特定 git/claude 事件触发、无交互的自动化 |

## 输出检查

产出文件前逐项验证：

- [ ] 产出物可直接使用（路径、格式正确）
- [ ] 去除了对话中的试错痕迹，只保留最终方案
- [ ] 描述触发条件明确（何时 AI 应激活）
- [ ] 不包含时间敏感信息
- [ ] 术语与项目现有保持统一
