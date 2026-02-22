# scv-ready

StarCraft 2 SCV voice lines for Claude Code. Your coding sessions now have a hard-working SCV providing commentary.

## Install

```bash
git clone git@github.com:AnthroPeon/scv-ready.git
cd scv-ready
./install.sh
```

Restart Claude Code to activate.

## What happens

| Event | SCV says |
|---|---|
| Session starts | "SCV ready!" / "SCV good to go, sir" |
| You submit a prompt | "Yes sir!" / "Roger" / "Will do" / "Big job, huh?" |
| Permission requested | "This is your plan?!" / "What, you run out of marines?" |
| Task completes | "Job's finished!" / "Well butter my biscuit!" |
| Bash command fails | "Oh, that's just great..." / "I can't build here" |
| Context compaction | "Woohoo! Overtime!" |

A 5-second cooldown prevents noise when using agent teams.
Important events (errors, task completion) always play through.

## Controls

```bash
# Mute
touch /path/to/scv-ready/.paused

# Unmute
rm /path/to/scv-ready/.paused
```

## Uninstall

```bash
./uninstall.sh
```

## Customize

Edit `sounds.json` to change which sounds play for which events.
All 65 SCV voice lines are included in `sounds/` — only the best are mapped by default.

Edit the `VOLUME` variable in `sc2-sounds.sh` to adjust volume (0.0 to 1.0, default 0.5).

## Requirements

- macOS (uses `afplay`)
- `jq` (`brew install jq`)
- Claude Code with hooks support

## How it works

Claude Code [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) trigger `sc2-sounds.sh` on events.
The script reads the event type, picks a random sound from the mapped pool (no repeats),
and plays it via `afplay` in the background.

Hooks are registered in `~/.claude/settings.json` with a `_source: "sc2-soundboard"` tag
so `uninstall.sh` can cleanly remove them without touching your other hooks.

## Credits

Sound files from StarCraft II by Blizzard Entertainment,
sourced from [nuclearlaunchdetected.com](https://nuclearlaunchdetected.com/).
