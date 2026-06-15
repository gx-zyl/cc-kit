import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import { readdir, readFile } from "node:fs/promises"
import { existsSync } from "node:fs"

const __dirname = dirname(fileURLToPath(import.meta.url))

export const CcKit: Plugin = async ({ project, client, $, directory, worktree }) => {
  const skillsDir = join(__dirname, "..", "skills")

  return {
    config: async (cfg) => {
      cfg.skills = cfg.skills || {}
      cfg.skills.paths = cfg.skills.paths || []
      if (!cfg.skills.paths.includes(skillsDir)) {
        cfg.skills.paths.push(skillsDir)
      }

      cfg.command = cfg.command || {}
      if (!cfg.command.publish) {
        cfg.command.publish = {
          description: "一键发布：更新文档 → commit → tag → push",
          template: `/publish <version>\n\n前置条件：运行前确认版本号已定好。\n1. 更新 README.md 顶部的 **v{version}** 和 AGENTS.md 的版本号\n2. git add -A && git commit -m "chore: bump version {version}"\n3. git tag -a cc-kit--v{version} -m "cc-kit v{version}"\n4. git push origin main --tags（需代理）`
        }
      }
      if (!cfg.command["wsl-chatgpt"]) {
        cfg.command["wsl-chatgpt"] = {
          description: "WSL 终端通过 Windows Chrome CDP 向 ChatGPT 提问",
          template: "调用 wsl-chatgpt skill，通过 CDP 桥接在 Windows Chrome 中操作 ChatGPT。\n- 有参数：直接作为问题发送\n- 无参数：从对话上下文提取最后一个问题\n- 依赖 skill：wsl-chatgpt、chrome-devtools-wsl"
        }
      }
    },

    tool: {
      "cc-kit-list": tool({
        description: "列出 cc-kit 合集所有 19 个技能的 name、description 和分类",
        args: {},
        async execute() {
          if (!existsSync(skillsDir)) {
            return `skills 目录不存在: ${skillsDir}`
          }
          const entries = await readdir(skillsDir, { withFileTypes: true })
          const dirs = entries.filter(d => d.isDirectory())
          const lines: string[] = []
          for (const d of dirs) {
            const skillPath = join(skillsDir, d.name, "SKILL.md")
            if (!existsSync(skillPath)) {
              lines.push(`- ${d.name}: (无 SKILL.md)`)
              continue
            }
            const content = await readFile(skillPath, "utf-8")
            const desc = content.match(/^description:\s*(.+)/m)
            lines.push(`- ${d.name}: ${desc ? desc[1] : "无描述"}`)
          }
          return `## cc-kit 技能清单 (${lines.length} 个)\n\n${lines.join("\n")}`
        }
      }),

      "cc-kit-diagnose": tool({
        description: "运行 cc-kit 健康检查：验证技能目录完整性、指令文件可读、配置一致性",
        args: {},
        async execute() {
          const issues: string[] = []
          const ok: string[] = []

          if (existsSync(skillsDir)) {
            const entries = await readdir(skillsDir, { withFileTypes: true })
            const dirs = entries.filter(d => d.isDirectory())
            ok.push(`skills 目录存在，含 ${dirs.length} 个子目录`)

            for (const d of dirs) {
              const skillPath = join(skillsDir, d.name, "SKILL.md")
              if (!existsSync(skillPath)) {
                issues.push(`${d.name}/SKILL.md 缺失`)
              } else {
                const content = await readFile(skillPath, "utf-8")
                if (!content.includes("name:")) issues.push(`${d.name}: 缺 name 字段`)
                if (!content.includes("description:")) issues.push(`${d.name}: 缺 description 字段`)
              }
            }
          } else {
            issues.push("skills 目录不存在")
          }

          const rulesDir = join(__dirname, "..", "rules")
          if (existsSync(rulesDir)) {
            const files = await readdir(rulesDir)
            ok.push(`rules 目录存在，含 ${files.length} 个文件`)
          } else {
            issues.push("rules 目录不存在")
          }

          const refsDir = join(__dirname, "..", "references")
          if (existsSync(refsDir)) {
            const files = await readdir(refsDir)
            ok.push(`references 目录存在，含 ${files.length} 个文件`)
          } else {
            issues.push("references 目录不存在")
          }

          let report = "## cc-kit 健康检查\n\n"
          report += `### 正常 (${ok.length})\n${ok.map(s => `  ✓ ${s}`).join("\n")}\n\n`
          report += `### 问题 (${issues.length})\n${issues.length ? issues.map(s => `  ✗ ${s}`).join("\n") : "  无"}\n`
          return report
        }
      })
    }
  }
}
