# Changelog

All notable changes to cc-kit will be documented in this file.

## [3.0.1] - 2026-06-29

### Removed
- **4 unused skills**: `coding-standards`, `huangting-protocol`, `postgres-patterns`, `wsl-chatgpt` (redundant/zero-trigger skills)
- `.claude/rules/CLAUDE.md` (triple duplicate with root and global CLAUDE.md)
- `fix1/` cleanup plan document

### Changed
- **Rules now ship with the plugin**: moved 4 rule files from `.claude/rules/` to plugin root `rules/`, with plugin-level `settings.json` distributing them via `instructions` array
- **WSL tool behavioral instructions** (`rg`/`fd`/`jq` over `grep`/`find`/`ps`) inlined into `CLAUDE.md` §5 for always-active loading
- `chrome-devtools-wsl/SKILL.md`: added reference files section pointing to `../../rules/`
- All stale cross-references fixed across README, SKILL tables, and w-ocean templates

### Fixed
- Dead glob `.claude/rules/*.md` in `.claude/settings.json` removed
- Broken link `README.md:125` pointing to old `.claude/rules/` path
- Stale architecture table describing non-existent `.claude/rules/` directory
- w-ocean template examples referencing deleted `coding-standards` skill
- `grow-dream-types.md` rule output path updated to new `rules/` location
