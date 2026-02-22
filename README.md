# SC2 SCV Soundboard for Claude Code

Your Claude Code sessions now have a hard-working SCV providing commentary.

## Install

```bash
git clone git@github.com:AnthroPeon/claude-sc2-soundboard.git
cd claude-sc2-soundboard
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
| Tool fails | "Oh, that's just great..." / "I can't build here" |
| Context compaction | "Woohoo! Overtime!" / "My cow died last night, so I don't need your bull" |

A 3-second cooldown prevents noise when using agent teams.

## Uninstall

```bash
./uninstall.sh
```

## Customize

Edit `sounds.json` to change which sounds play for which events.
All 65 SCV voice lines are included in `sounds/` — only the best are mapped by default.

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
