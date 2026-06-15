---
name: chrome-devtools-wsl
description: 操控 Windows Chrome — 导航/截图/JS/CDP/API 桥接，替代 web-access CDP Proxy
tags: [chrome, devtools, wsl, cdp, browser, automation, web-access]
compatibility: opencode
---

# Chrome DevTools for WSL

PowerShell → Windows Python → CDP 操控 Chrome。无需中继，不依赖防火墙。

## 首次配置

首次使用复制 `.env.example` 为 `.env` 并编辑（`just` 自动加载）：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CCW_DIR` | `D:\chrome-devtools-wsl` | Windows 工作目录（脚本部署 + Chrome profile） |
| `PYWIN` | 自动查找 | Windows Python（留空则 PowerShell 自动获取 `(Get-Command python.exe).Source`） |
| `CDP_PORT` | `9222` | Chrome DevTools 端口 |

通常只需确认 `CCW_DIR` 指向有写入权限的路径即可，其余自动检测。

## 命令

```bash
# 插件安装路径（通过 marketplace 安装）
cd ~/.claude/plugins/marketplaces/cc-kit/plugin/skills/chrome-devtools-wsl

# 开发路径
cd D:\project\cc-kit\plugin\skills\chrome-devtools-wsl

just start          启动 Chrome（带 remote-debugging）
just stop           关闭 Chrome
just status         查看状态
just nav <url>      打开 URL（默认 chatgpt.com）
just shot [name]    截图
just eval <js>      执行 JS
just ask "问题"     向 ChatGPT 提问
just serve          启动 web-access 兼容 API (localhost:3456)
```

## 架构

```
WSL                            Windows
─────────────────              ───────────────
just nav                        Chrome
  ↓                             (127.0.0.1:9222)
cdp-bridge.py (3456)                ↑
  ↓                             chrome_debug.py
PowerShell ───────────────►     Windows Python → CDP
```

## 与 web-access 的关系

| web-access 组件 | chrome-devtools-wsl 替代方案 |
|----------------|---------------------------|
| CDP Proxy (cdp-proxy.mjs) | `just serve` → cdp-bridge.py（兼容相同 curl API） |
| Chrome 生命周期 | `just start/stop` |
| 浏览哲学 / 站点经验 | **未替代**，继续用 web-access |

启动 Chrome → `just start`，然后 `just serve` 启动 API 桥接，web-access 的 curl 脚本无需修改即可正常工作。
