---
name: wsl-chatgpt
description: WSL 终端通过 Windows Chrome CDP 向 ChatGPT 提问，回答返回当前对话
---

# wsl-chatgpt

调用 `wsl-chatgpt` skill，通过 CDP 桥接在 Windows Chrome 中操作 ChatGPT。

## 使用

`/wsl-chatgpt [你的问题]`

- **有参数**：直接作为问题发送
- **无参数**：从对话上下文提取最后一个问题
- **无法确定问题**：停止，要求补充

## 依赖 skill

| skill | 作用 |
|-------|------|
| `wsl-chatgpt` | ChatGPT 交互流程 |
| `chrome-devtools-wsl` | CDP 桥接层 |

前置条件和故障排查见 `wsl-chatgpt` skill。
