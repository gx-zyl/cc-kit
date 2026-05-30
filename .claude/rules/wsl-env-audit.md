# WSL 环境审计规则

> WSL 环境健康检查清单，覆盖 Claude Code 插件、MCP、工具链、版本管理、代理配置。
> 建议在系统更新、插件变动、或定期维护 WSL 环境时执行。

---

## 检查清单

### 一、Claude Code 插件

| # | 检查 | 方法 |
|---|------|------|
| A1 | 全部插件 ✔ enabled | `claude plugin list` |
| A2 | 版本是否为最新 | `claude plugin update <name>` |
| A3 | settings 与实际一致 | 对比 `claude plugin list` |
| A4 | marketplace source 路径正确 | 每个目录存在 |
| A5 | 无残留 marketplace 目录 | 与 extraKnownMarketplaces 逐项比对 |

### 二、MCP 配置

| # | 检查 | 方法 |
|---|------|------|
| B1 | mcp.json 格式合法 | `jq . ~/.claude/mcp.json` |
| B2 | 入口路径匹配当前版本 | 版本号校验 |
| B3 | command 可执行 | `which bun` / `which node` |
| B4 | 无重复 MCP 配置 | `find ~/.claude -name mcp.json` |

### 三、工具链版本

| # | 检查 | 方法 |
|---|------|------|
| C1 | Claude Code 最新版 | 重跑安装脚本 |
| C2 | mise 自身更新 | `mise self-update` |
| C3 | npm 全局包过期 | `npm outdated -g` |
| C4 | cargo 残留工具 | `ls ~/.cargo/bin/`，核对卸载清单 |
| C5 | apt 有待更新包 | `apt list --upgradable` |

### 四、WSL 环境集成

| # | 检查 | 说明 |
|---|------|------|
| D1 | WSL 网关 IP | `cat /etc/resolv.conf \| grep nameserver \| awk '{print $2}'` |
| D2 | WSL → Windows 网络 | CDP 端口 9222 可达 |
| D3 | Git 远程认证 | HTTPS PAT 或 SSH |
| D4 | Docker 可用 | `docker info` |
| D5 | 国内镜像可达 | npmmirror + tuna |

---

## 一键审计

```bash
echo "=== WSL 网关 ===" && cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
echo "=== Plugins ===" && claude plugin list 2>&1
echo "=== MCP ===" && cat ~/.claude/mcp.json && jq . ~/.claude/mcp.json >/dev/null 2>&1 && echo "格式 OK" || echo "格式错误"
echo "=== Claude Version ===" && claude --version 2>/dev/null
echo "=== Mise ===" && mise --version && mise ls 2>&1 | head -5
echo "=== npm outdated ===" && npm outdated -g --depth=0 2>&1
echo "=== Cargo残留 ===" && ls ~/.cargo/bin/ 2>/dev/null || echo "无"
echo "=== Docker ===" && docker info 2>&1 | head -2
echo "=== APT ===" && apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0"
echo "=== WSL→Win ===" && curl -s --connect-timeout 3 "http://$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):9222/json/version" >/dev/null 2>&1 && echo "通" || echo "不通"
echo "=== 镜像 ===" && curl -s --connect-timeout 3 https://registry.npmmirror.com -o /dev/null -w "npm:%{http_code} " && curl -s --connect-timeout 3 https://mirrors.tuna.tsinghua.edu.cn -o /dev/null -w "tuna:%{http_code}" && echo ""
```
