---
name: handoff
description: 把当前对话压缩成交接文档，方便另一个 AI agent 接力。带"推荐技能"章节。
argument-hint: "下个会话要做什么？"
compatibility: opencode
---

把当前对话总结成交接文档，让一个全新的 AI 能继续工作。保存到系统的临时目录，不要放到项目目录里。

文档中包含"推荐技能"章节，建议接力 agent 需要调用的 skills。

不要重复已有产物（PRD、计划、ADR、issue、commit、diff）中的内容，用路径或 URL 引用即可。

脱敏敏感信息（API 密钥、密码、个人身份信息）。

如果用户传了参数，按参数描述的用途重点写文档。
