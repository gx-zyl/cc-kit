# cc-kit — OpenCode Skill Collection v1.7.0

> Skills count: 19 (update this when adding/removing skills in `plugin/skills/`)

## Project Layout

| Path | Purpose |
|------|---------|
| `plugin/skills/` | 19 skills (loaded via plugin) |
| `plugin/commands/` | Claude-native commands (deprecated) |
| `.claude/rules/` | Environment & dev tool rules (loaded via `instructions`) |
| `.claude/references/` | Reference docs (loaded via `instructions`) |
| `.opencode/plugin/cc-kit.ts` | OpenCode plugin: injects skills.paths + commands |
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

- Source of truth: `plugin/skills/<name>/SKILL.md` (single source, dual compatibility)
- All skills have `compatibility: opencode` in frontmatter
- PowerShell on Windows, `pwsh` shell
