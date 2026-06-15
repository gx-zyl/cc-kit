import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import { readdir, readFile } from "node:fs/promises"
import { existsSync } from "node:fs"

const __dirname = dirname(fileURLToPath(import.meta.url))

/**
 * Parse YAML frontmatter from a markdown file.
 * Returns { name, description } or null if no valid frontmatter.
 */
function parseFrontmatter(content: string): { name?: string; description?: string } | null {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---/)
  if (!match) return null
  const frontmatter: Record<string, string> = {}
  for (const line of match[1].split("\n")) {
    const kv = line.match(/^(\w+):\s*(.+)/)
    if (kv) frontmatter[kv[1]] = kv[2].trim()
  }
  return frontmatter.name || frontmatter.description ? frontmatter : null
}

export const CcKit: Plugin = async ({ project, client, $, directory, worktree }) => {
  const skillsDir = join(__dirname, "..", "skills")

  return {
    config: async (cfg) => {
      cfg.skills = cfg.skills || {}
      cfg.skills.paths = cfg.skills.paths || []
      if (!cfg.skills.paths.includes(skillsDir)) {
        cfg.skills.paths.push(skillsDir)
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
            const fm = parseFrontmatter(content)
            lines.push(`- ${fm?.name ?? d.name}: ${fm?.description ?? "无描述"}`)
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
                const fm = parseFrontmatter(content)
                if (!fm || !fm.name) issues.push(`${d.name}: 缺 name 字段`)
                if (!fm || !fm.description) issues.push(`${d.name}: 缺 description 字段`)
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
