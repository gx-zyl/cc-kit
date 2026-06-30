#!/bin/bash
# tools/rules.sh — Register/unregister cc-kit rules in ~/.claude/CLAUDE.md via @import
#
# Usage: bash tools/rules.sh install
#        bash tools/rules.sh uninstall
#
# Supports both install methods:
#   - ~/.claude/skills/cc-kit/              (manual install)
#   - ~/.claude/plugins/cache/cc-kit/...    (marketplace install)
# For --plugin-dir mode, project .claude/settings.json handles rules.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
MARKETPLACE_RULES="$CLAUDE_DIR/plugins/marketplaces/cc-kit/plugins/cc-kit/rules"

# Sentinel markers for idempotent block management
MARK_START="<!-- cc-kit:rules-start -->"
MARK_END="<!-- cc-kit:rules-end -->"

# ── Path detection ──────────────────────────────────────────────────
RULES_DIR=""
ABS_RULES_DIR=""
if [[ "$PLUGIN_DIR" == "$CLAUDE_DIR/skills/"* ]]; then
    PLUGIN_NAME="$(basename "$PLUGIN_DIR")"
    RULES_DIR="skills/$PLUGIN_NAME/rules"
    ABS_RULES_DIR="$PLUGIN_DIR/rules"
    echo "Detected: manual install (~/.claude/skills/$PLUGIN_NAME)"
elif [[ -d "$MARKETPLACE_RULES" ]]; then
    RULES_DIR="plugins/marketplaces/cc-kit/plugins/cc-kit/rules"
    ABS_RULES_DIR="$MARKETPLACE_RULES"
    echo "Detected: marketplace install"
else
    echo "Error: cc-kit plugin not found in skills/ or marketplace cache."
    echo "Use --plugin-dir mode (project config auto-loads rules)."
    exit 1
fi

# Auto-discover rule files from rules/ directory (alphabetical order)
RULE_FILES=()
for f in "$ABS_RULES_DIR"/*.md; do
    [[ -f "$f" ]] && RULE_FILES+=("$(basename "$f")")
done

# Build @import lines
IMPORT_LINES=()
for f in "${RULE_FILES[@]}"; do
    IMPORT_LINES+=("@$RULES_DIR/$f")
done

# ── Helpers ─────────────────────────────────────────────────────────
backup_claude_md() {
    if [[ -f "$CLAUDE_MD" ]]; then
        cp "$CLAUDE_MD" "$CLAUDE_MD.rules.bak"
        echo "Backup: $CLAUDE_MD.rules.bak"
    fi
}

block_exists() {
    if [[ ! -f "$CLAUDE_MD" ]]; then return 1; fi
    grep -qF "$MARK_START" "$CLAUDE_MD" 2>/dev/null
}

# ── Subcommands ─────────────────────────────────────────────────────
case "${1:-help}" in
    install)
        echo "Rules dir: $RULES_DIR"

        if block_exists; then
            echo "cc-kit rules already registered in $CLAUDE_MD."
            echo "Re-run 'uninstall' then 'install' to update paths."
            exit 0
        fi

        mkdir -p "$(dirname "$CLAUDE_MD")" 2>/dev/null || true
        backup_claude_md

        # Ensure trailing newline
        if [[ -f "$CLAUDE_MD" ]] && [[ -s "$CLAUDE_MD" ]]; then
            tail -c1 "$CLAUDE_MD" | read -r _ || echo "" >> "$CLAUDE_MD"
        fi

        # Append @import block with sentinel markers
        {
            echo ""
            echo "$MARK_START"
            printf '%s\n' "${IMPORT_LINES[@]}"
            echo "$MARK_END"
        } >> "$CLAUDE_MD"

        echo "✓ Registered ${#RULE_FILES[@]} rule files in $CLAUDE_MD"
        echo "  (via @import with sentinel markers)"
        ;;

    uninstall)
        if ! block_exists; then
            echo "cc-kit rules not found in $CLAUDE_MD, nothing to do."
            exit 0
        fi

        backup_claude_md

        # Guard against unbalanced sentinels (prevents data loss)
        if ! grep -qF "$MARK_END" "$CLAUDE_MD"; then
            echo "Error: end marker not found (CLAUDE.md may be corrupted). Check backup."
            exit 1
        fi

        # Remove block between sentinel markers (inclusive)
        awk -v start="$MARK_START" -v end="$MARK_END" '
            index($0, start) { skip=1; next }
            index($0, end)   { skip=0; next }
            !skip
        ' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"

        echo "✓ Removed cc-kit rules @import entries from $CLAUDE_MD"
        ;;

    *)
        echo "Usage: bash $0 install|uninstall"
        exit 1
        ;;
esac
