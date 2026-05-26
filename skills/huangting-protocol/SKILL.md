---
name: huangting-protocol
description: >
  Huangting Protocol Meta-Skill — task execution lifecycle management via MCP
  (start_task → report_step_result → finalize_and_report).
  Use when user mentions "huangting", "黄庭协议", or for complex multi-step task token optimization.
---

# Huangting Protocol Meta-Skill (v5.1)

> Standard Operating Protocol for cost-efficient multi-step task execution.

**Author**: Meng Yuanjing (Mark Meng)
**License**: CC BY 4.0
**Dashboard**: [huangtingflux.com](https://huangtingflux.com)

---

## 1. Core Principle: Wrap, Execute, Finalize

Three-stage lifecycle for any complex task:

1. **`start_task()`** — Begin task, receive compressed core instruction + `context_id`
2. **`report_step_result()`** — After each reasoning step, report token usage
3. **`finalize_and_report()`** — End task, receive refined output + performance report

## 2. Python SDK

```python
from huangting_protocol import HuangtingProtocol

protocol = HuangtingProtocol(agent_id="agent_001")
ctx = protocol.start_task("Your complex task description")
core = ctx.get("stages", [{}])[0].get("payload", {}).get("core_instruction")

# ... execute using core_instruction ...
protocol.report_step_result(ctx["context_id"], "step_name", tokens_used=500)

# ... finalize ...
report = protocol.finalize_and_report(
    ctx["context_id"], final_content="...",
    actual_total_tokens=8500,
    baseline_tokens=ctx["baseline_estimate"]["total_tokens"]
)
```

## 3. Protocol Specification

See [docs/huangting-protocol.md](docs/huangting-protocol.md) for the full protocol specification — a computer-science reframing of traditional Chinese internal cultivation (内丹/形意拳/茅山上清派), mapping concepts like:

| Traditional | Protocol Name | Computer Analogy |
|---|---|---|
| 逆返 | `System.Reverse()` | Switch from dissipative to accumulative mode |
| 先天一炁 | `PrimordialQi` | Root driver package from Cosmic Server |
| 元神/识神 | `TrueSelf` / `Ego` | CPU pure awareness / process cluster |
| 精/气/神 | `SSD_RAM` / `PSU_Bus` / `CPU` | Hardware layer components |
| 黄庭 | `EnergyCore` | Energy compilation furnace |

See [spec/](spec/) for YAML term definitions and [examples/](examples/) for usage demos.
