# Changelog

All notable changes to cc-kit will be documented in this file.

## [3.0.2] - 2026-06-30

### Fixed (critical)
- **Rules 分发机制实际上不工作**：Claude Code 的 instructions 路径解析只扫描两个位置——`~/.claude/settings.json` 和 `<项目根>/.claude/settings.json`——**插件内的 `.claude/settings.json` 和插件根 `settings.json` 均不被扫描**。v3.0.1 把规则搬到 `rules/` 并依赖插件级 `settings.json` 分发的设计是无效的。

### Added
- **`tools/rules.sh` / `tools/rules.ps1`**：子命令分发脚本（`install` / `uninstall`），合并原 4 个独立文件，共享路径检测逻辑。向 `~/.claude/settings.json` 追加/移除 `skills/cc-kit/rules/*.md` 条目
- README.md 全局安装步骤后补充规则注册步骤

### Changed
- `chrome-devtools-wsl/SKILL.md`：修正"规则始终加载"的误导性描述
- README.md 架构表：修正规则分发说明，明确本地开发 vs 全局安装的区别

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
