---
name: wsl-chatgpt
description: WSL 通过 CDP 桥接 Windows Chrome，自动化操作 ChatGPT 网页（提问、获取回答）。用户说 wsl-chatgpt、wsl 问 chatgpt、wsl chatgpt、浏览器 chatgpt、从 wsl 问 ai 时触发。
compatibility: claude
---

# WSL ChatGPT

WSL 环境通过 CDP 桥接 Windows Chrome，实现终端直接操作 ChatGPT 网页。

```
WSL 终端                      Windows
─────────────────              ─────────────────
/wsl-chatgpt "问题"            Chrome (localhost:9222)
  ↓                               ↑
wsl-chatgpt skill              CDP 协议
  ↓                               ↑
PowerShell ───────────────►    chrome_debug.py
```

## 前置条件

1. Windows Chrome 已开启远程调试：
   ```cmd
   "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
   ```
2. CDP Bridge 已启动（WSL 内执行）：
   ```bash
   cd .claude/skills/chrome-devtools-wsl
   just start   # 启动 Chrome（如需）
   just serve   # 启动 API 桥接 (localhost:3456)
   ```
   > **备选**：也可用外部 skill `web-access` 的 CDP Proxy（需单独安装，不在 cc-kit 内）：
   > ```bash
   > CDP_HOST=$(ip route show default | awk '{print $3}') node ~/.claude/skills/web-access/scripts/cdp-proxy.mjs &
   > ```
   > 推荐优先使用 `chrome-devtools-wsl` 的 `just serve`，无需额外依赖。
3. Chrome 已登录 ChatGPT

## 流程

### 1. 打开 ChatGPT

```bash
curl -s "http://localhost:3456/new?url=https://chatgpt.com"
# 返回: {"targetId":"xxx"}
```

保存 `targetId`，后续操作都通过这个 ID。

### 2. 等待页面就绪

```bash
sleep 5
curl -s "http://localhost:3456/info?target=xxx"
# 应返回: {"title":"ChatGPT","url":"https://chatgpt.com/","ready":"complete"}
```

### 3. 定位输入框

ChatGPT 页面有两个输入元素：

| 元素 | Selector | 可用 |
|------|----------|------|
| textarea | `textarea.wcDTda_fallbackTextarea` | 否（隐藏回退） |
| div | `div#prompt-textarea` | **是** |

```bash
curl -s -X POST "http://localhost:3456/eval?target=xxx" \
  -d "document.querySelector('#prompt-textarea')?.tagName"
# 应返回: "DIV"
```

### 4. 输入问题

```bash
curl -s -X POST "http://localhost:3456/eval?target=xxx" \
  -d '(() => { const inp = document.querySelector("#prompt-textarea"); inp.textContent = "实际问题"; inp.dispatchEvent(new InputEvent("input", {bubbles: true})); return "ok"; })()'
```

### 5. 提交问题

```bash
curl -s -X POST "http://localhost:3456/eval?target=xxx" \
  -d "(() => { const btn = document.querySelector('button[data-testid=\"send-button\"]'); btn?.click(); return btn ? 'clicked' : 'btn not found'; })()"
```

### 6. 等待回复

轮询检查 assistant 消息（最多等待 60 秒）：

```bash
# 轮询循环，最多 60 秒
for i in {1..12}; do
  sleep 5
  RESPONSE=$(curl -s -X POST "http://localhost:3456/eval?target=xxx" \
    -d "document.querySelector('[data-message-author-role=\"assistant\"]')?.textContent || 'waiting...'")
  if [ "$RESPONSE" != "waiting..." ]; then
    echo "$RESPONSE"
    break
  fi
  if [ $i -eq 12 ]; then
    echo "ERROR: 回复超时（60秒）"
  fi
done
```

### 7. 提取回答

```bash
curl -s -X POST "http://localhost:3456/eval?target=xxx" \
  -d "document.querySelector('[data-message-author-role=\"assistant\"]')?.textContent"
```

### 8. 关闭 tab

```bash
curl -s "http://localhost:3456/close?target=xxx"
```

## 故障排查

### Bridge 显示 connected:false

**原因**：Chrome 未启动或 CDP 端口不通

**解决**：
```bash
# 用 chrome-devtools-wsl 启动：
cd .claude/skills/chrome-devtools-wsl
just start && just serve
```

### 消息提交后无回复

**排查**：
1. 截图确认页面状态：
   ```bash
   curl -s "http://localhost:3456/screenshot?target=xxx&file=/tmp/chat.png"
   ```
2. 确认使用的是 `div#prompt-textarea` 而非 textarea
3. 确认发送按钮被点击成功
4. 检查 ChatGPT 是否要求登录或验证

### Chrome 连接失败（WSL → Windows）

确认 WSL 能访问 Windows 主机（防火墙放行 9222 端口）：

```bash
# 获取 Windows 主机 IP
WIN_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
# 测试 CDP 端口
curl "http://$WIN_IP:9222/json/version"
```

若不通，放行 CDP 端口：
```cmd
netsh advfirewall firewall add rule name="WSL Chrome CDP" dir=in action=allow protocol=TCP localport=9222
```

## 验证方法

```bash
# 1. 验证 Chrome CDP 可达
curl http://$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):9222/json/version

# 2. 验证 Bridge 已连接
curl http://localhost:3456/health

# 3. 列出可用 tab
curl http://localhost:3456/targets
```
