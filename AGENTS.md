# cc-kit — OpenCode Skill Collection v1.8.0

> Skills count: 19 (update this when adding/removing skills in `.opencode/skills/`)

## Project Layout

| Path | Purpose |
|------|---------|
| `.opencode/skills/` | 19 skills (auto-discovered by OpenCode) |
| `.opencode/commands/` | publish、wsl-chatgpt 命令 |
| `.opencode/rules/` | Environment & dev tool rules (loaded via `instructions`) |
| `.opencode/references/` | Reference docs (grow-dream types, skill structure) |
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
- PowerShell on Windows, `pwsh` shell
