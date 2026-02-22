#!/bin/bash
# uninstall.sh - Remove SC2 SCV soundboard hooks from Claude Code
set -euo pipefail

echo "=== Uninstalling SC2 SCV Soundboard ==="

SETTINGS_FILE="$HOME/.claude/settings.json"
STATE_DIR="${TMPDIR:-/tmp}/sc2-soundboard"

# Remove hooks from settings.json
if [ -f "$SETTINGS_FILE" ]; then
  jq '
    if .hooks then
      .hooks |= with_entries(
        .value |= map(select(._source != "sc2-soundboard"))
      ) |
      .hooks |= with_entries(select(.value | length > 0)) |
      if (.hooks | length) == 0 then del(.hooks) else . end
    else . end
  ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  echo "Removed hooks from ~/.claude/settings.json"
else
  echo "No settings.json found."
fi

# Clean up state
rm -rf "$STATE_DIR"
echo "Cleaned up temp state."

echo ""
echo "Done. Restart Claude Code for changes to take effect."
