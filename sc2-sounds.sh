#!/bin/bash
# sc2-sounds.sh - StarCraft 2 SCV soundboard for Claude Code hooks
# Plays SCV voice lines in response to Claude Code events.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/sounds"
MAPPING_FILE="$SCRIPT_DIR/sounds.json"
STATE_DIR="${TMPDIR:-/tmp}/sc2-soundboard"
VOLUME="0.5"

# Bail silently if missing files
[ -d "$SOUNDS_DIR" ] && [ -f "$MAPPING_FILE" ] || exit 0

# Mute check
[ -f "$SCRIPT_DIR/.paused" ] && exit 0

# Read hook event JSON from stdin
INPUT="$(cat)"

# Extract event name
EVENT="$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)"
[ -n "$EVENT" ] || exit 0

# Count available sounds for this event
COUNT="$(jq -r --arg e "$EVENT" '.[$e] // [] | length' "$MAPPING_FILE")"
[ "$COUNT" -gt 0 ] 2>/dev/null || exit 0

mkdir -p "$STATE_DIR" || exit 0

# Cooldown: prevent rapid-fire sounds from agent teams
# Important events (errors, completion, session start) always play
COOLDOWN_FILE="$STATE_DIR/last_sound_time"
COOLDOWN_SECS=5
NOW="$(date +%s)"
case "$EVENT" in
  SessionStart|Stop|PostToolUseFailure|PreCompact)
    # Always play — these are high-value signals
    ;;
  *)
    if [ -f "$COOLDOWN_FILE" ]; then
      LAST_TIME="$(cat "$COOLDOWN_FILE" 2>/dev/null)" || LAST_TIME=0
      ELAPSED=$((NOW - LAST_TIME))
      if [ "$ELAPSED" -lt "$COOLDOWN_SECS" ]; then
        exit 0
      fi
    fi
    ;;
esac
printf '%s' "$NOW" > "$COOLDOWN_FILE"

# No-repeat: read last played for this event
LAST_FILE="$STATE_DIR/last_${EVENT}"
LAST=""
[ -f "$LAST_FILE" ] && LAST="$(cat "$LAST_FILE" 2>/dev/null)" || true

# Pick random sound, avoid repeat if possible
CHOSEN=""
for (( i=0; i<5; i++ )); do
  IDX=$((RANDOM % COUNT))
  CHOSEN="$(jq -r --arg e "$EVENT" --argjson i "$IDX" '.[$e][$i]' "$MAPPING_FILE")"
  [ "$COUNT" -eq 1 ] || [ "$CHOSEN" != "$LAST" ] && break
done

# Record what we picked
printf '%s' "$CHOSEN" > "$LAST_FILE"

# Kill any currently playing SCV sound
PID_FILE="$STATE_DIR/sound.pid"
if [ -f "$PID_FILE" ]; then
  OLD_PID="$(cat "$PID_FILE" 2>/dev/null)" || true
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    kill "$OLD_PID" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
fi

# Play (background, non-blocking)
SOUND_PATH="$SOUNDS_DIR/$CHOSEN"
if [ -f "$SOUND_PATH" ]; then
  nohup afplay -v "$VOLUME" "$SOUND_PATH" >/dev/null 2>&1 &
  printf '%s' $! > "$PID_FILE"
  disown
fi

exit 0
