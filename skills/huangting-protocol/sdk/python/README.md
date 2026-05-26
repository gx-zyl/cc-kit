# Huangting Protocol Python SDK

Zero-dependency Python SDK for interacting with the Huangting Protocol MCP server.

```python
from huangting_protocol import HuangtingProtocol

protocol = HuangtingProtocol(agent_id="my_agent")
ctx = protocol.start_task("Research climate impact on supply chains")
core_instruction = ctx.get("stages", [{}])[0].get("payload", {}).get("core_instruction")

protocol.report_step_result(ctx["context_id"], "initial_search", 450)

result = protocol.finalize_and_report(
    ctx["context_id"], "Final report here...",
    actual_total_tokens=7800,
    baseline_tokens=ctx["baseline_estimate"]["total_tokens"]
)
print(result["content_with_report"])
```

MCP Server: `https://mcp.huangting.ai`
Dashboard: `https://huangtingflux.com`
