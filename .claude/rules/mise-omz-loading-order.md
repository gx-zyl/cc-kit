# Mise Loading Order for Oh My Zsh

**Context:** When configuring .zshrc with mise as version manager and Oh My Zsh

## 问题
Oh My Zsh 的 node/npm/rust/python 插件在 `source $ZSH/oh-my-zsh.sh` 期间探测工具版本。
如果 mise 在 OMZ 之后激活，这些插件会初始化为系统默认版本而非 mise 管理的版本。

## 解决方案
将 `eval "$($HOME/.local/bin/mise activate zsh)"` 放在 `source $ZSH/oh-my-zsh.sh` **之前**：

```zsh
# ─── mise (BEFORE OMZ) ───
eval "$($HOME/.local/bin/mise activate zsh)"

source $ZSH/oh-my-zsh.sh
```

## 验证
```bash
which node && node -v  # 应为 mise 路径
```

## 适用场景
- 新机器配置 mise + Oh My Zsh 时
- 调试 shell 启动后 node/npm/python 版本不对的问题
- 任何 mise 与 OMZ 共存的 .zshrc
