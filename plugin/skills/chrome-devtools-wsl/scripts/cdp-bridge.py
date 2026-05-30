"""
CDP Bridge — WSL HTTP + WebSocket API 服务
把 web-access 和 browser-harness 的请求转到 Windows Chrome CDP。

API:  localhost:3456  (HTTP, web-access 兼容)
WS:   localhost:9223  (WebSocket, browser-harness 用 BU_CDP_WS)
"""
import http.server, json, os, subprocess, time, urllib.parse, threading, asyncio, sys
import websockets

PORT_HTTP = 3456
PORT_WS = 9223
PWSH = ["powershell.exe", "-NoProfile", "-Command"]

# Windows 工作目录：$env:CCW_DIR > 默认
_WIN_WORK = os.environ.get("CCW_DIR", r"D:\chrome-devtools-wsl")
WIN_SCRIPT = os.path.join(_WIN_WORK, "chrome_debug.py")

def _find_win_python():
    """Windows Python：$env:PYWIN > PowerShell 查找 > 回退 python.exe"""
    pw = os.environ.get("PYWIN")
    if pw:
        return pw
    try:
        r = subprocess.run(PWSH + ["(Get-Command python.exe -ErrorAction SilentlyContinue).Source"],
                         capture_output=True, text=True, timeout=10)
        if r.returncode == 0 and r.stdout.strip():
            return r.stdout.strip()
    except Exception:
        pass
    return "python.exe"

PYWIN = _find_win_python()


def win_run(*args):
    """在 Windows 上执行 chrome_debug.py，返回 stdout"""
    cmd = f"& '{PYWIN}' '{WIN_SCRIPT}' " + " ".join(f"'{a}'" for a in args)
    r = subprocess.run(PWSH + [cmd], capture_output=True, text=True, timeout=60)
    return r.stdout.strip()


def _get_win_ip():
    """获取 Windows 主机 IP（缓存）"""
    try:
        with open('/etc/resolv.conf') as f:
            for line in f:
                if 'nameserver' in line:
                    return line.split()[1]
    except Exception:
        return None

_WIN_IP = _get_win_ip()
_ws_url_cache = None  # (url, timestamp)


def _get_cached_ws_url():
    """获取浏览器级 WS URL（缓存 30 秒，避免每次消息都调 PowerShell）"""
    global _ws_url_cache
    now = time.time()
    if _ws_url_cache is None or now - _ws_url_cache[1] > 30:
        try:
            r = win_run("json")
            info = json.loads(r) if r else {}
            _ws_url_cache = (info.get("wsUrl", ""), now)
        except Exception:
            _ws_url_cache = ("", now)
    return _ws_url_cache[0]


# ─── HTTP API (web-access 兼容) ─────────────────────

class HttpHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[bridge] http {args[0]} {args[1]} {args[2]}")

    def _json(self, data, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode())

    def _text(self, text, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(text.encode())

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)

        if path == "/health":
            r = win_run("json")
            try:
                ok = json.loads(r).get("status") == "running"
                self._json({"connected": ok, "chrome": ok})
            except Exception:
                self._json({"connected": False, "chrome": False})
        elif path == "/targets":
            self._json([{"targetId": "_"}])
        elif path == "/new":
            win_run("nav", qs.get("url", ["https://chatgpt.com"])[0])
            self._json({"targetId": "new"})
        elif path == "/screenshot":
            win_run("shot", "cdp_bridge")
            self._text("ok")
        elif path == "/close":
            self._json({})
        elif path == "/info":
            self._json({"title": "ChatGPT", "url": "?", "ready": "complete"})
        else:
            self._text("ok")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode() if length > 0 else ""
        if urllib.parse.urlparse(self.path).path == "/eval":
            self._text(win_run("eval", body.strip() or "document.title"))
        else:
            self._text("ok")

    do_PUT = do_POST


# ─── WebSocket (browser-harness 用 BU_CDP_WS) ─────

async def ws_handler(ws):
    """WebSocket 代理：每条消息作为 CDP 命令转发到 Windows Chrome"""
    print("[bridge] WS 客户端已连接")
    try:
        while True:
            raw = await asyncio.wait_for(ws.recv(), timeout=300)
            msg = json.loads(raw)
            mid = msg.get("id", 0)
            method = msg.get("method", "")
            params = msg.get("params", {})

            if method == "Target.getTargets":
                await ws.send(json.dumps(
                    {"id": mid, "result": {"targetInfos": [{"targetId": "page_1", "type": "page", "title": "bridge", "url": "https://chatgpt.com", "attached": True}]}}
                ))
                continue

            # 获取 Chrome WS URL（缓存），翻译为 WSL→Windows 地址
            ws_url = _get_cached_ws_url()
            if not ws_url:
                ws_url = "ws://127.0.0.1:9222/devtools/browser"
            if _WIN_IP:
                ws_url = ws_url.replace('127.0.0.1', _WIN_IP).replace('localhost', _WIN_IP)

            # WSL 进程内直接 WebSocket，不再走 PowerShell→子进程
            try:
                async with websockets.connect(ws_url, max_size=2**20, open_timeout=15) as cdp_ws:
                    await cdp_ws.send(json.dumps({"id": 1, "method": method, "params": params}))
                    result = json.loads(await cdp_ws.recv())
                await ws.send(json.dumps({"id": mid, **result}))
            except Exception as e:
                await ws.send(json.dumps({"id": mid, "error": {"code": -1, "message": str(e)[:200]}}))

    except asyncio.TimeoutError:
        pass
    except Exception:
        pass
    print("[bridge] WS 客户端断开")


async def ws_server():
    async with websockets.serve(ws_handler, "0.0.0.0", PORT_WS, ping_interval=None):
        print(f"[bridge] ws://localhost:{PORT_WS}  (browser-harness: BU_CDP_WS=ws://localhost:{PORT_WS})")
        await asyncio.Future()


# ─── 启动 ────────────────────────────────────────────

def run_http():
    server = http.server.HTTPServer(("0.0.0.0", PORT_HTTP), HttpHandler)
    print(f"[bridge] http://localhost:{PORT_HTTP}  (web-access 兼容)")
    server.serve_forever()


def main():
    print(f"[bridge] CDP Bridge 启动")
    print(f"[bridge] WSL 进程内 WebSocket → Windows Chrome CDP (gateway: {_WIN_IP or 'auto'})")
    # HTTP 在单独线程运行
    t = threading.Thread(target=run_http, daemon=True)
    t.start()
    # WebSocket 在主线程 asyncio 运行
    asyncio.run(ws_server())


if __name__ == "__main__":
    main()
