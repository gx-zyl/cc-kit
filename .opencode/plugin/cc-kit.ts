import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const __dirname = dirname(fileURLToPath(import.meta.url))

export default async () => {
  const skillsDir = join(__dirname, "..", "..", "plugin", "skills")

  return {
    config: (cfg: Record<string, any>) => {
      cfg.skills = cfg.skills || {}
      cfg.skills.paths = cfg.skills.paths || []
      if (!cfg.skills.paths.includes(skillsDir)) {
        cfg.skills.paths.push(skillsDir)
      }

      cfg.command = cfg.command || {}
      if (!cfg.command.publish) {
        cfg.command.publish = {
          description: "一键发布：更新文档 → commit → tag → push",
          template: "/publish <version>\n\n前置条件：运行前确认版本号已定好。\n1. 更新 plugin/plugin.json、.claude-plugin/marketplace.json、README.md 中的版本号\n2. git add -A && git commit\n3. git tag -a cc-kit--v{version}\n4. git push origin main --tags（需代理）"
        }
      }
      if (!cfg.command["wsl-chatgpt"]) {
        cfg.command["wsl-chatgpt"] = {
          description: "WSL 终端通过 Windows Chrome CDP 向 ChatGPT 提问",
          template: "调用 wsl-chatgpt skill，通过 CDP 桥接在 Windows Chrome 中操作 ChatGPT。\n- 有参数：直接作为问题发送\n- 无参数：从对话上下文提取最后一个问题\n- 依赖 skill：wsl-chatgpt、chrome-devtools-wsl"
        }
      }
    }
  }
}
