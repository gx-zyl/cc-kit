#!/bin/bash
# tools/rules.sh — Register/unregister cc-kit rules in ~/.claude/settings.json
#
# Usage: bash tools/rules.sh install
#        bash tools/rules.sh uninstall
#
# Prerequisite: jq
#
# Only supports global install (~/.claude/skills/cc-kit/).
# For --plugin-dir mode, project .claude/settings.json already handles rules.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# ── Path detection (shared) ─────────────────────────────────────────
if [[ "$PLUGIN_DIR" == "$CLAUDE_DIR/skills/"* ]]; then
    PLUGIN_NAME="$(basename "$PLUGIN_DIR")"
else
    echo "Error: cc-kit is not installed under ~/.claude/skills/."
    echo "Use --plugin-dir mode instead (project .claude/settings.json has rules)."
    exit 1
fi

INSTR_ENTRY="skills/$PLUGIN_NAME/rules/*.md"

# ── Subcommands ─────────────────────────────────────────────────────
case "${1:-help}" in
    install)
        echo "Detected: ~/.claude/skills/$PLUGIN_NAME"
        echo "Entry: $INSTR_ENTRY"

        # Ensure settings.json exists; backup if present
        if [[ ! -f "$SETTINGS_FILE" ]]; then
            mkdir -p "$(dirname "$SETTINGS_FILE")" 2>/dev/null || true
            echo '{}' > "$SETTINGS_FILE"
        else
            cp "$SETTINGS_FILE" "$SETTINGS_FILE.rules.bak"
            echo "Backup: $SETTINGS_FILE.rules.bak"
        fi

        # Append entry (idempotent)
        if ! jq --arg e "$INSTR_ENTRY" '
            if has("instructions") then
                if (.instructions | index($e)) then .
                else .instructions += [$e] end
            else .instructions = [$e] end
        ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"; then
            rm -f "$SETTINGS_FILE.tmp"
            echo "Error: jq failed. Is jq installed?"
            exit 1
        fi
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "✓ Registered: $INSTR_ENTRY"
        ;;

    uninstall)
        echo "Entry: $INSTR_ENTRY"

        if [[ ! -f "$SETTINGS_FILE" ]]; then
            echo "Settings file not found, nothing to do."
            exit 0
        fi

        cp "$SETTINGS_FILE" "$SETTINGS_FILE.rules.bak"
        echo "Backup: $SETTINGS_FILE.rules.bak"

        # Remove entry; leave empty array instead of deleting key
        if ! jq --arg e "$INSTR_ENTRY" '
            if has("instructions") then
                .instructions |= map(select(. != $e))
            else . end
        ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"; then
            rm -f "$SETTINGS_FILE.tmp"
            echo "Error: jq failed. Is jq installed?"
            exit 1
        fi
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "✓ Removed: $INSTR_ENTRY"
        ;;

    *)
        echo "Usage: bash $0 install|uninstall"
        exit 1
        ;;
esac
