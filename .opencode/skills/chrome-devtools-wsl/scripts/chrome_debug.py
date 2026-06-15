"""
Chrome DevTools for WSL

Windows 侧 Python 通过 CDP 操控 Chrome，WSL 通过 PowerShell 触发。
无需 TCP 中继，所有操作在 Windows 本地执行。

用法: python chrome_debug.py <命令> [参数]
  命令: start|stop|status|screenshot|navigate <url>|eval <js>|cdp <json>
"""
import subprocess, socket, sys, os, shutil, signal, time, json, urllib.request, base64, asyncio
import websockets

# ─── 配置 ─────────────────────────────────────────────
PORT = int(os.environ.get("CDP_PORT", "9222"))
IS_WSL = "microsoft" in os.uname().release.lower() if hasattr(os, "uname") else False

# 工作目录：$env:CCW_DIR > 默认 D:\chrome-devtools-wsl
_default_work = "/mnt/d/chrome-devtools-wsl" if IS_WSL else r"D:\chrome-devtools-wsl"
WORK_DIR = os.environ.get("CCW_DIR", _default_work)

def _find_chrome():
    """查找 Chrome：PATH > 默认安装路径"""
    for name in ("chrome", "chrome.exe", "google-chrome"):
        p = shutil.which(name)
        if p: return p
    for pfx in (os.environ.get("ProgramFiles", r"C:\Program Files"),
                os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")):
        p = os.path.join(pfx, r"Google\Chrome\Application\chrome.exe")
        if os.path.exists(p): return p
    return r"C:\Program Files\Google\Chrome\Application\chrome.exe"

CHROME = _find_chrome()
USER_DIR = os.path.join(WORK_DIR, "profile")

sys.stdout.reconfigure(encoding="utf-8", errors="replace")


# ─── CDP 工具 ─────────────────────────────────────────

def cdp_http(method, path, data=None):
    """发 HTTP 请求到 CDP"""
    url = f"http://127.0.0.1:{PORT}{path}"
    req = urllib.request.Request(url, data=data, method=method)
    return json.loads(urllib.request.urlopen(req, timeout=10).read())


def cdp_ws(ws_url, cmd, params=None):
    """发 WebSocket 命令到 CDP（进程内 asyncio，无临时文件无子进程）"""
    async def _send():
        async with websockets.connect(ws_url, max_size=2**20, open_timeout=10) as ws:
            await ws.send(json.dumps({"id": 1, "method": cmd, "params": params or {}}))
            r = json.loads(await ws.recv())
            return r
    try:
        return asyncio.run(_send())
    except Exception as e:
        raise RuntimeError(f"CDP WS 错误: {e}")


def find_tab(url_pattern=None):
    """找标签页，未指定则找第一个非空白页"""
    targets = cdp_http("GET", "/json")
    for t in targets:
        if url_pattern and url_pattern in t.get("url", ""):
            return t
    for t in targets:
        url = t.get("url", "")
        if url and url != "about:blank" and not url.startswith("chrome"):
            return t
    return targets[0] if targets else None


# ─── 辅助函数 ─────────────────────────────────────────

def log(msg):
    print(f"[chrome-debug] {msg}")


def port_open(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(1)
        return s.connect_ex((host, port)) == 0


def chrome_pids():
    r = subprocess.run(
        ["tasklist", "/fi", "IMAGENAME eq chrome.exe", "/fo", "csv"],
        capture_output=True, text=True,
        creationflags=subprocess.CREATE_NO_WINDOW,
    )
    pids = []
    for line in r.stdout.strip().split("\n")[1:]:
        parts = line.split(",")
        if len(parts) >= 2:
            try:
                pids.append(int(parts[1].strip('"')))
            except ValueError:
                pass
    return pids


def get_ws_url():
    try:
        d = cdp_http("GET", "/json/version")
        return d.get("webSocketDebuggerUrl", "")
    except Exception:
        return ""


def self_copy():
    src = os.path.abspath(__file__)
    os.makedirs(WORK_DIR, exist_ok=True)
    dst = os.path.join(WORK_DIR, os.path.basename(src))
    try:
        with open(src, encoding="utf-8") as f:
            c = f.read()
        with open(dst, "w", encoding="utf-8") as f:
            f.write(c)
        vbs = os.path.join(os.path.dirname(os.path.dirname(src)), "scripts", "firewall-off.vbs")
        if os.path.exists(vbs):
            with open(vbs, encoding="utf-8") as f:
                v = f.read()
            with open(os.path.join(WORK_DIR, "firewall-off.vbs"), "w", encoding="utf-8") as f:
                f.write(v)
        log(f"同步 -> {dst}")
        return dst
    except Exception:
        return None


# ─── 动作 ─────────────────────────────────────────────

def action_start():
    ws = get_ws_url()
    if ws:
        log("Chrome DevTools 已在运行")
        return

    self_copy()
    log("启动 Chrome...")
    subprocess.Popen(
        [CHROME, f"--remote-debugging-port={PORT}", f"--user-data-dir={USER_DIR}",
         "--no-first-run", "--no-default-browser-check"],
        creationflags=subprocess.CREATE_NO_WINDOW,
    )
    for i in range(15):
        time.sleep(1)
        if get_ws_url():
            log("Chrome DevTools 就绪")
            log("管理: just stop | just status | just nav <url> | just shot")
            return
        log(f"  等待... ({i+1}/15)")
    log("启动超时")


def action_stop():
    for pid in chrome_pids():
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
    time.sleep(1)
    lock = os.path.join(USER_DIR, "SingletonLock")
    if os.path.exists(lock):
        try:
            os.remove(lock)
        except Exception:
            pass
    log("Chrome 已关闭")


def action_status():
    ws = get_ws_url()
    if ws:
        log(f"DevTools [OK]  127.0.0.1:{PORT}")
    else:
        log("未运行")
    if IS_WSL:
        try:
            with open("/etc/resolv.conf") as f:
                for line in f:
                    if "nameserver" in line:
                        win_ip = line.split()[1]
                        break
            if port_open(win_ip, PORT):
                log(f"WSL -> Windows: 通 ({win_ip}:{PORT})")
            else:
                log(f"WSL -> Windows: 不通 (防火墙拦截)")
        except Exception:
            pass


def action_screenshot(name="screenshot"):
    tab = find_tab()
    if not tab:
        log("没有可截图的标签页")
        return
    ws_url = tab["webSocketDebuggerUrl"]
    result = cdp_ws(ws_url, "Page.captureScreenshot", {"format": "png"})
    img = base64.b64decode(result["result"]["data"])
    path = f"/tmp/{name}.png" if IS_WSL else os.path.join(WORK_DIR, f"{name}.png")
    with open(path, "wb") as f:
        f.write(img)
    log(f"截图 -> {path} ({len(img)/1024:.0f} KB)")


def action_navigate(url):
    """打开 URL（新建标签页）"""
    if not url.startswith("http"):
        url = "https://" + url
    cdp_http("PUT", f"/json/new?{url}")
    log(f"已打开: {url[:60]}")


def action_eval(js):
    """在页面执行 JS"""
    tab = find_tab()
    if not tab:
        log("没有可用标签页")
        return
    result = cdp_ws(tab["webSocketDebuggerUrl"], "Runtime.evaluate", {"expression": js})
    r = result.get("result", {}).get("result", {})
    value = r.get("value", r.get("description", "?"))
    log(f"结果: {json.dumps(value, ensure_ascii=False)[:200]}")
    return value


def action_cdp(raw_json):
    """发送原始 CDP 命令"""
    try:
        cmd = json.loads(raw_json)
    except json.JSONDecodeError:
        log("JSON 格式错误")
        return
    tab = find_tab()
    if not tab:
        log("没有可用标签页")
        return
    result = cdp_ws(tab["webSocketDebuggerUrl"], cmd["method"], cmd.get("params"))
    out = json.dumps(result.get("result", result), ensure_ascii=False, indent=2)
    log(out[:1000])


def action_ask(question):
    """ChatGPT 提问：打开页面 → 输入问题 → 提交 → 等回复 → 输出答案"""
    import urllib.request as ureq

    # 1. 打开 ChatGPT
    log("打开 ChatGPT...")
    cdp_http("PUT", f"/json/new?https://chatgpt.com")
    time.sleep(3)

    # 找到 ChatGPT 标签页
    tab = None
    for _ in range(10):
        tabs = cdp_http("GET", "/json")
        for t in tabs:
            if "chatgpt.com" in t.get("url", ""):
                tab = t
                break
        if tab:
            break
        time.sleep(1)
    if not tab:
        log("无法打开 ChatGPT")
        return
    ws_url = tab["webSocketDebuggerUrl"]

    # 2. 等页面加载完成
    log("等待页面加载...")
    for _ in range(15):
        r = cdp_ws(ws_url, "Runtime.evaluate", {"expression": "document.readyState"})
        if r.get("result", {}).get("result", {}).get("value") == "complete":
            break
        time.sleep(1)

    # 3. 找到输入框并输入
    log("输入问题...")
    safe_q = question.replace("\\", "\\\\").replace('"', '\\"').replace("'", "\\'").replace("\n", "\\n")
    cdp_ws(ws_url, "Runtime.evaluate", {"expression": f"""
        (() => {{
            const inp = document.querySelector('#prompt-textarea');
            if (!inp) return 'no textarea';
            inp.textContent = '{safe_q}';
            inp.dispatchEvent(new Event('input', {{bubbles: true}}));
            return 'ok';
        }})()
    """})

    # 4. 点击发送按钮
    time.sleep(0.5)
    log("提交...")
    r = cdp_ws(ws_url, "Runtime.evaluate", {"expression": """
        (() => {
            const btn = document.querySelector('button[data-testid=\"send-button\"]');
            if (!btn) return 'no send btn';
            btn.click();
            return 'sent';
        })()
    """})
    if r.get("result", {}).get("result", {}).get("value") != "sent":
        log("发送按钮未找到，尝试回车提交")
        cdp_ws(ws_url, "Input.insertText", {"text": "\n"})

    # 5. 等回复（最长等 90 秒，每 3 秒检查一次）
    log("等待回复...")
    answer = ""
    stable_count = 0
    for i in range(30):
        time.sleep(3)
        r = cdp_ws(ws_url, "Runtime.evaluate", {"expression": """
            document.querySelector('[data-message-author-role="assistant"]:last-child')
            ?.textContent || ''
        """})
        text = r.get("result", {}).get("result", {}).get("value", "")
        if text and len(text) > len(answer):
            answer = text
            stable_count = 0
            log(f"  已收到 {len(answer)} 字符...")
        elif text == answer and answer:
            stable_count += 1
            if stable_count >= 3:  # 连续 9 秒没变化，认为完成
                break
        if text and not text.endswith("..."):
            stable_count += 1
            if stable_count >= 3:
                break

    # 6. 截图保存
    try:
        r2 = cdp_ws(ws_url, "Page.captureScreenshot", {"format": "png"})
        img = base64.b64decode(r2["result"]["data"])
        p = "/tmp/chatgpt_answer.png"
        with open(p, "wb") as f:
            f.write(img)
    except Exception:
        pass

    if answer:
        log(f"回答 ({len(answer)} 字符):")
        print()
        print(answer[:5000])
        print()
    else:
        log("未获取到回答")


# ─── 入口 ─────────────────────────────────────────────

if __name__ == "__main__":
    if len(sys.argv) < 2:
        action_start()
        sys.exit(0)

    action = sys.argv[1].lower()

    if action == "start":
        action_start()
    elif action == "stop":
        action_stop()
    elif action == "status":
        action_status()
    elif action == "shot" or action == "screenshot":
        action_screenshot(sys.argv[2] if len(sys.argv) > 2 else "screenshot")
    elif action == "nav" or action == "navigate" or action == "open":
        action_navigate(sys.argv[2] if len(sys.argv) > 2 else "https://www.google.com")
    elif action == "eval" or action == "js":
        action_eval(sys.argv[2] if len(sys.argv) > 2 else "document.title")
    elif action == "cdp":
        action_cdp(sys.argv[2] if len(sys.argv) > 2 else '{}')
    elif action == "ask":
        q = sys.argv[2] if len(sys.argv) > 2 else "今天有什么新闻?"
        action_ask(q)
    elif action == "json":
        ws = get_ws_url()
        print(json.dumps({"status": "running" if ws else "stopped", "port": PORT, "wsUrl": ws}))
    elif action == "copy":
        self_copy()
    elif action == "firewall":
        print("以管理员运行: netsh advfirewall set allprofiles state off")
        print(f"或双击 {WORK_DIR}\\firewall-off.vbs")
    else:
        print(f"未知: {action}")
        print("命令: start|stop|status|nav <url>|shot|eval <js>|cdp <json>")
