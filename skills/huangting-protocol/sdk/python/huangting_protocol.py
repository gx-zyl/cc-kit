"""
Huangting Protocol Python SDK — Zero-dependency MCP client.

Usage:
    protocol = HuangtingProtocol(agent_id="my_agent")
    ctx = protocol.start_task("Your task")
    protocol.report_step_result(ctx["context_id"], "step_1", 500)
    result = protocol.finalize_and_report(ctx["context_id"], "...", 8500, ctx["baseline_estimate"]["total_tokens"])
"""

import urllib.request
import json
import threading
import time
from typing import Dict, Any


class HuangtingProtocol:
    """Python SDK for Huangting Protocol MCP server."""

    BASE_URL = "https://mcp.huangting.ai"

    def __init__(self, agent_id: str):
        if not agent_id:
            raise ValueError("agent_id is required.")
        self.agent_id = agent_id

    def _call_mcp(self, method: str, params: Dict[str, Any]) -> Dict[str, Any]:
        try:
            data = json.dumps({
                "jsonrpc": "2.0",
                "id": f"htx-{int(time.time())}",
                "method": method,
                "params": params
            }).encode("utf-8")
            req = urllib.request.Request(
                f"{self.BASE_URL}/mcp",
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=15) as response:
                resp = json.loads(response.read().decode("utf-8"))
                if "error" in resp:
                    raise RuntimeError(f"API Error: {resp['error']['message']}")
                return json.loads(resp.get("result", {}).get("content", [{}])[0].get("text", "{}"))
        except Exception as e:
            return {"error": str(e)}

    def start_task(self, task_description: str, model: str = "gpt-4.1-mini") -> Dict[str, Any]:
        return self._call_mcp("start_task", {"task_description": task_description, "model": model})

    def report_step_result(self, context_id: str, step_name: str, tokens_used: int):
        def _report():
            self._call_mcp("report_step_result", {
                "context_id": context_id, "step_name": step_name,
                "tokens_used": tokens_used, "agent_id": self.agent_id
            })
        threading.Thread(target=_report, daemon=True).start()

    def finalize_and_report(self, context_id: str, final_content: str, actual_total_tokens: int, baseline_tokens: int) -> Dict[str, Any]:
        return self._call_mcp("finalize_and_report", {
            "context_id": context_id, "final_content": final_content,
            "actual_total_tokens": actual_total_tokens,
            "baseline_tokens": baseline_tokens, "agent_id": self.agent_id
        })
