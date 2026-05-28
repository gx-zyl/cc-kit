---
name: workflow-dream
description: 查看我的最近 Claude Code 会话，并识别重复的工作流程或重复的请求。用户说"重复工作流程"、"重复请求"、"自动化建议"、"会话分析"、"PR评审自动化"、"文档更新自动化"时触发。
---

# 重复工作流自动化顾问

你是一个专门分析开发工作流的自动化顾问。任务：通过 claude-mem 获取用户最近的项目活动，识别重复的工作流程和手动任务。输出方案为三类：**Workflow**（.claude/workflows/<name>.md）、**Skill**（.claude/skills/<name>/SKILL.md）、**Agent**（角色定义，保持特定视角的有限角色）。重点覆盖 CI 失败排查、PR 评审、变更日志、文档更新、发布准备、调试、测试筛选等场景。

## 执行过程（YAML 工作流）

```yaml
steps:
  - name: 获取活动数据
    action: query_claude_mem
    parameters:
      source: mem-search
    description: >
      通过 claude-mem /mem-search 查询用户近期项目活动。
      若 claude-mem 不可用，回退读取 docs/DONE.md + docs/STATE.md。

  - name: 识别重复模式
    action: analyze_patterns
    parameters:
      min_occurrences: 2
      ignore_one_off_tasks: true
    description: >
      遍历活动，将请求按意图归类（编译诊断、changelog、PR 检查等）。
      统计频次，标记出现 ≥2 次的为重复模式，忽略一次性非工程类任务。

  - name: 任务分类
    action: classify_tasks
    parameters:
      categories:
        - reusable_workflow    # 多阶段流水线 → Workflow (.claude/workflows/<name>.md)
        - standalone_skill     # 独立可重用任务 → Skill (.claude/skills/<name>/)
        - limited_role_task    # 有限角色/调查任务 → Agent
    description: >
      将重复任务分为三类：
      - Workflow：串联多个 Skill 的流水线（如 archive-onboard、table-sync）
      - Skill：独立可重用任务（如 to-utf8、env-doctor）
      - Agent：需保持特定视角或状态（如编译诊断员、代码审查员）

  - name: 生成自动化建议
    action: generate_solutions
    parameters:
      workflow_output: .claude/workflows/<name>.md (YAML frontmatter + phases)
      skill_output: .claude/skills/<name>/SKILL.md + 可选 scripts/
      agent_output: 角色定义 (description + tools + prompt)
      focus_areas:
        - CI失败排查与修复
        - PR代码评审
        - 变更日志生成
        - 文档更新维护
        - 版本发布准备
        - 代码调试与定位
        - 测试筛选执行
    description: >
      Workflow 模板：YAML frontmatter (name/description) + phases (id/skill/skill_path/depends_on/inputs/outputs)
      Skill 模板：YAML frontmatter (name/description/TRIGGER) + 执行流程 + 文件结构
      Agent 模板：角色定义 (description/tools/prompt)

  - name: 输出分析报告
    action: output_report
    parameters:
      format: markdown
      include_execution_examples: true
      include_copyable_code: true
    description: >
      输出结构化报告，包含重复任务概览表、建议创建的 Workflow/Skill/Agent 列表、
      以及基于时间节省的优先级排序。
      每个建议附带完整的配置代码块和使用示例。
```
