---
name: make-dream
description: 总结对话经验，提取可复用模式，产出 command / skill / workflow / agent / hook。用户说"造梦"、"总结对话"、"提炼经验"、"固化模式"、"make dream"时触发。
---

# Make Dream — 对话经验结构化

分析当前对话或指定内容，提取重复模式、决策逻辑、知识沉淀，产出结构化可复用产出。

## 流程

1. **输入源** — 确定分析范围：
   - 本次对话
   - 指定对话日志（路径）
   - git log / commit message
   - 特定文件/目录的修改历史

2. **提炼** — 识别可固化要素：
   - 重复 ≥2 次的操作 → 命令/脚本
   - 特定场景的解题套路 → skill
   - 多步骤编排流程 → workflow
   - 需要独立判断的任务 → agent
   - 自动触发条件 → hook

3. **产出** — 用户选择格式生成

## 产出格式

### command → `plugin/skills/<name>/SKILL.md`
确定性操作，可直接写成 claude command。条件：步骤固定、无需 AI 判断。

### skill → `plugin/skills/<name>/SKILL.md`
场景化能力封装，含 description、触发条件、流程步骤。条件：有判断分支、需要上下文理解。

### workflow → `.claude/workflows/<name>.yml`
多步骤编排，可串行/并行调用 agent。条件：需要多个独立步骤、步骤间有数据传递。

### agent → `.claude/agents/<name>.md`
独立自主角色，有明确职责和边界。条件：需要持续运行、有决策自主权、面向特定领域。

### hook → `.claude/hook.<event>.sh`
事件触发行为。条件：特定 git/claude 事件触发、无交互的自动化操作。

## 输出检查

- [ ] 产出物可直接使用（路径、格式正确）
- [ ] 去除了对话中的试错痕迹，只保留最终方案
- [ ] 描述触发条件明确（何时 AI 应激活）
- [ ] 不包含时间敏感信息
- [ ] 术语与项目现有保持统一
