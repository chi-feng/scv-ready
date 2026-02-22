#!/bin/bash
# uninstall.sh - Remove SC2 SCV soundboard hooks from Claude Code
set -euo pipefail

echo "=== Uninstalling SC2 SCV Soundboard ==="

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
STATE_DIR="${TMPDIR:-/tmp}/sc2-soundboard"

# Remove hooks from settings.json
if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"

  # Remove entries matching _source tag OR command path (belt + suspenders)
  jq --arg cmd "$INSTALL_DIR/sc2-sounds.sh" '
    if .hooks then
      .hooks |= with_entries(
        .value |= map(select(
          (._source != "sc2-soundboard") and
          (.hooks | all(.command != $cmd))
        ))
      ) |
      .hooks |= with_entries(select(.value | length > 0)) |
      if (.hooks | length) == 0 then del(.hooks) else . end
    else . end
  ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  echo "Removed hooks from ~/.claude/settings.json"
  echo "Backup saved to ${SETTINGS_FILE}.bak"
else
  echo "No settings.json found."
fi

# Clean up state and pause file
rm -rf "$STATE_DIR"
rm -f "$INSTALL_DIR/.paused"
echo "Cleaned up."

echo ""
echo "Done. Restart Claude Code for changes to take effect."
