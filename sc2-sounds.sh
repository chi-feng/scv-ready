#!/bin/bash
# sc2-sounds.sh - StarCraft 2 SCV soundboard for Claude Code hooks
# Plays SCV voice lines in response to Claude Code events.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$SCRIPT_DIR/sounds"
MAPPING_FILE="$SCRIPT_DIR/sounds.json"
STATE_DIR="${TMPDIR:-/tmp}/sc2-soundboard"

# Bail silently if missing files
[ -d "$SOUNDS_DIR" ] && [ -f "$MAPPING_FILE" ] || exit 0

# Read hook event JSON from stdin
INPUT="$(cat)"

# Extract event name
EVENT="$(echo "$INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null)"
[ -n "$EVENT" ] || exit 0

# Count available sounds for this event
COUNT="$(jq -r --arg e "$EVENT" '.[$e] // [] | length' "$MAPPING_FILE")"
[ "$COUNT" -gt 0 ] 2>/dev/null || exit 0

mkdir -p "$STATE_DIR"

# Cooldown: skip if a sound played within the last N seconds
# Prevents noise when agent teams fire many events rapidly
COOLDOWN_FILE="$STATE_DIR/last_sound_time"
COOLDOWN_SECS=3
NOW="$(date +%s)"
if [ -f "$COOLDOWN_FILE" ]; then
  LAST_TIME="$(cat "$COOLDOWN_FILE" 2>/dev/null)" || LAST_TIME=0
  ELAPSED=$((NOW - LAST_TIME))
  # SessionStart always plays (greeting), others respect cooldown
  if [ "$EVENT" != "SessionStart" ] && [ "$ELAPSED" -lt "$COOLDOWN_SECS" ]; then
    exit 0
  fi
fi
printf '%s' "$NOW" > "$COOLDOWN_FILE"

# No-repeat: read last played for this event
LAST_FILE="$STATE_DIR/last_${EVENT}"
LAST=""
[ -f "$LAST_FILE" ] && LAST="$(cat "$LAST_FILE" 2>/dev/null)" || true

# Pick random sound, avoid repeat if possible
MAX_TRIES=5
CHOSEN=""
for _ in $(seq 1 $MAX_TRIES); do
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
  [ -n "$OLD_PID" ] && kill "$OLD_PID" 2>/dev/null || true
fi

# Play (background, non-blocking)
SOUND_PATH="$SOUNDS_DIR/$CHOSEN"
if [ -f "$SOUND_PATH" ]; then
  afplay "$SOUND_PATH" &
  echo $! > "$PID_FILE"
  disown
fi

exit 0
