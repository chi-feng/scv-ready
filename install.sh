#!/bin/bash
# install.sh - Install SC2 SCV soundboard hooks for Claude Code
set -euo pipefail

echo "=== SC2 SCV Soundboard for Claude Code ==="
echo ""

# Check prerequisites
for cmd in jq afplay; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd is required. Install with: brew install $cmd"; exit 1; }
done

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_CMD="$INSTALL_DIR/sc2-sounds.sh"

# Ensure ~/.claude/settings.json exists
mkdir -p "$HOME/.claude"
[ -f "$SETTINGS_FILE" ] || echo '{}' > "$SETTINGS_FILE"

# Check for existing installation
if jq -e '.hooks // {} | to_entries[] | select(.value | type == "array") | .value[] | select(._source == "sc2-soundboard")' "$SETTINGS_FILE" >/dev/null 2>&1; then
  echo "Already installed. Run ./uninstall.sh first to reinstall."
  exit 1
fi

# Verify sounds exist
SOUND_COUNT=$(ls "$INSTALL_DIR/sounds/"*.mp3 2>/dev/null | wc -l | tr -d ' ')
echo "Found $SOUND_COUNT sound files."
[ "$SOUND_COUNT" -gt 0 ] || { echo "Error: No MP3 files in sounds/. Something is wrong."; exit 1; }

# Make scripts executable
chmod +x "$HOOK_CMD" "$INSTALL_DIR/uninstall.sh"

# Register hooks in settings.json
TEMP=$(mktemp)
cp "$SETTINGS_FILE" "$TEMP"

# Events and their config: event_name:async:matcher
HOOK_CONFIGS=(
  "SessionStart:true:"
  "Stop:true:"
  "UserPromptSubmit:true:"
  "PermissionRequest:true:"
  "PostToolUseFailure:true:Bash"
  "PreCompact:true:"
)

for CONFIG in "${HOOK_CONFIGS[@]}"; do
  EVENT="${CONFIG%%:*}"
  REST="${CONFIG#*:}"
  ASYNC="${REST%%:*}"
  MATCHER="${REST#*:}"

  NEW_ENTRY=$(jq -n --arg cmd "$HOOK_CMD" --argjson async "$ASYNC" --arg matcher "$MATCHER" '{
    "_source": "sc2-soundboard",
    "matcher": (if $matcher == "" then "" else $matcher end),
    "hooks": [{
      "type": "command",
      "command": $cmd,
      "timeout": 5,
      "async": $async
    }]
  } | if .matcher == "" then del(.matcher) else . end')

  jq --arg event "$EVENT" --argjson entry "$NEW_ENTRY" '
    .hooks //= {} |
    .hooks[$event] //= [] |
    .hooks[$event] += [$entry]
  ' "$TEMP" > "${TEMP}.out" && mv "${TEMP}.out" "$TEMP"
done

mv "$TEMP" "$SETTINGS_FILE"

# Play test sound
echo ""
echo "Hooks registered for: SessionStart, Stop, UserPromptSubmit,"
echo "  PermissionRequest, PostToolUseFailure (Bash only), PreCompact"
echo ""
nohup afplay -v 0.5 "$INSTALL_DIR/sounds/SCV_Ready00.mp3" >/dev/null 2>&1 &
disown
echo "Installation complete! Restart Claude Code to hear your SCV."
echo ""
echo "Controls:"
echo "  Mute:   touch $INSTALL_DIR/.paused"
echo "  Unmute: rm $INSTALL_DIR/.paused"
echo "  Remove: ./uninstall.sh"
