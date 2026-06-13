---
name: huangting-protocol
description: 黄庭协议 Meta-Skill — 通过 MCP 管理任务执行生命周期（start_task → report_step_result → finalize_and_report）。用户说"黄庭协议"、"huangting"、"token 优化"时触发。
compatibility: opencode
---

# 黄庭协议 Meta-Skill (v5.1)

> 复杂多步任务的标准执行协议，提高 token 使用效率。

**作者**：孟元景 | **协议**：CC BY 4.0
**面板**：[huangtingflux.com](https://huangtingflux.com)

---

## 1. 核心：包裹 → 执行 → 终结

复杂任务的三阶段生命周期：

1. **`start_task()`** — 开始任务，接收压缩的核心指令 + `context_id`
2. **`report_step_result()`** — 每个推理步骤后报告 token 用量
3. **`finalize_and_report()`** — 结束任务，接收精炼输出 + 性能报告

## 2. Python SDK

```python
from huangting_protocol import HuangtingProtocol

protocol = HuangtingProtocol(agent_id="agent_001")
ctx = protocol.start_task("你的复杂任务描述")
core = ctx.get("stages", [{}])[0].get("payload", {}).get("core_instruction")

# ... 用 core_instruction 执行 ...
protocol.report_step_result(ctx["context_id"], "step_name", tokens_used=500)

# ... 结束 ...
report = protocol.finalize_and_report(
    ctx["context_id"], final_content="...",
    actual_total_tokens=8500,
    baseline_tokens=ctx["baseline_estimate"]["total_tokens"]
)
```

## 3. 协议规范

详见 [docs/huangting-protocol.md](docs/huangting-protocol.md) — 将传统内丹/形意拳/茅山上清派修炼用计算机科学重述：

| 传统概念 | 协议名 | 计算机关比 |
|---|---|---|
| 逆返 | `System.Reverse()` | 从耗散切换到积累模式 |
| 先天一炁 | `PrimordialQi` | 宇宙服务器的根驱动包 |
| 元神/识神 | `TrueSelf` / `Ego` | CPU 纯觉知 / 进程集合 |
| 精/气/神 | `SSD_RAM` / `PSU_Bus` / `CPU` | 硬件层组件 |
| 黄庭 | `EnergyCore` | 能源编译炉 |

详见 [spec/](spec/) YAML 术语定义。
