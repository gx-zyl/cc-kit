# cc-kit — OpenCode Skill Collection v2.0.0

> Skills count: 19 (update this when adding/removing skills in `.opencode/skills/`)

## Project Layout

| Path | Purpose |
|------|---------|
| `.opencode/skills/` | 19 skills with YAML frontmatter (name + description + triggers) |
| `.opencode/command/` | publish、wsl-chatgpt 命令（oh-my-openagent 约定） |
| `.opencode/commands/` | 同 command/，兼容旧版路径 |
| `.opencode/rules/` | Environment & dev tool rules (loaded via `instructions`) |
| `.opencode/references/` | Reference docs (grow-dream types, skill structure) |
| `.opencode/AGENTS.md` | Project-scope agent instructions |
| `.opencode/memory/` | Persistent project memory |

## Key Commands

| Command | Description |
|---------|-------------|
| `publish <version>` | Bump version → commit → tag → push |
| `wsl-chatgpt [question]` | Send question via WSL Chrome CDP |

## Workflows

- **release** — Bump version, tag, push, marketplace update
- **marketplace-doctor** — Diagnose & fix version misalignment

## Conventions

- Source of truth: `.opencode/skills/<name>/SKILL.md`
- Skill frontmatter: `name` + `description` (trigger words embedded in description)
- Command frontmatter: `description` + optional `argument-hint`
- PowerShell on Windows, `pwsh` shell
