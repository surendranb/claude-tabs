# claude-tabs

Snapshot, list, and restore [Claude Code](https://docs.claude.com/en/docs/claude-code) CLI sessions across terminal tabs. *Built with Claude Code itself.*

🌐 **[Visit the Website](https://claude-tabs.builditwithai.xyz)**

## Install

```sh
curl -fsSL https://claude-tabs.builditwithai.xyz/install | sh
```

Picks a writable directory on your `$PATH` automatically. Falls back to `~/.local/bin` (no sudo) or `/usr/local/bin` (with sudo). Single Python 3 file, stdlib only.

## Save

Run before quitting your terminal.

```
$ claude-tabs save
Saved 8 sessions → ~/.claude/saved-sessions/20260509-184959.jsonl

$ claude-tabs list
[1] ~/code/marketing-os
    5779c1ed…  •  79 turns  •  ~6d 21h  •  main
    Title: I've a very important project for you. There are two...
    Last:  what branch are we in?
[2] ~/code/marketing-os/v2/atlan-marketing-team
    103501f9…  •  37 turns  •  ~1h 56m  •  project/account-engagement
    Title: the account engagement dashboard from last week was...
    Last:  Now the changes to the score - there are 10 elements...
    ...
```

Bare `claude-tabs` is shorthand for `list`. `list` accepts `--full`, `--all`, `--json`.

## Restore

After re-opening your terminal.

```
$ claude-tabs restore 1 2
→ ~/code/marketing-os  (5779c1ed…)
→ ~/code/marketing-os/v2/atlan-marketing-team  (103501f9…)
opened 2 tabs via terminal.
```

```sh
claude-tabs restore               # all
claude-tabs restore -i            # interactive picker
claude-tabs restore -w            # one window per session
claude-tabs restore --print       # emit shell; pipe to sh on any OS
claude-tabs restore 1 4 7         # by index or session-id prefix
```

Auto-picks Terminal.app / iTerm / tmux / `--print` from `$TERM_PROGRAM` and `$TMUX`. Tabs work in iTerm and tmux out of the box. Terminal.app gets tabs once you grant System Events Accessibility (System Settings → Privacy & Security → Accessibility); until then it falls back to new windows automatically and prints how to enable.

## What's saved, where, and how it's used

`claude-tabs` runs entirely on your machine. **No network calls, no telemetry, nothing leaves your laptop.** You can verify with `grep -E 'urllib|requests|http\.|socket' claude-tabs` — it returns nothing.

`save` writes one JSONL file per snapshot to `~/.claude/saved-sessions/<timestamp>.jsonl`, mode `0600` (user-only). Each line is one session and contains:

| field | source |
|---|---|
| `cwd`, `session_id`, `pid`, `resumed` | from `ps` and `lsof` on the live `claude` process |
| `started_at`, `last_active`, `duration` | timestamps from the session's jsonl on disk |
| `turns` | count of user prompts in the jsonl |
| `title` | first user message, **truncated to 240 chars** |
| `last_prompt` | most recent user message, **truncated to 240 chars** |
| `git_branch`, `model`, `permission_mode` | last values seen in the jsonl |
| `size_bytes`, `_schema` | file size and snapshot schema version |

The underlying transcripts already exist on disk under `~/.claude/projects/` — `claude-tabs` reads them and writes a small extract. `list` reads back the snapshot for display; `restore` reads `cwd` + `session_id` and runs `claude --resume <id>`. That's it.

If you share a snapshot file with someone (e.g. for debugging this tool), treat it like you'd treat the underlying transcripts — `title` and `last_prompt` are real prompt text and may contain anything you typed.

## Notes

- macOS-only for `save` (uses `lsof` + `ps`). `restore --print` works on any OS.
- Run `save` while sessions are alive — once you quit, the cwd↔session pairing is lost.
- `save` matches each running `claude` to its session jsonl by start-time + cwd, with UUID validation to refuse anything that doesn't look like a real Claude Code session.

## License

MIT.
