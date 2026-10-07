# Ghostty + herdr setup guide

> Saved verbatim from the original setup session (2026-10-07). One change since then:
> the Ghostty config moved from `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
> to `~/.config/ghostty/config.ghostty`, which is the path chezmoi now manages.

---

Both configs validate with no diagnostics, and herdr's running server has reloaded the new one.

## What I set up

**Ghostty** (`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`)
- The theme is Gruvbox Dark, to match herdr.
- Left Option works as Alt, and right Option still types special characters.
- Closing a window no longer asks for confirmation, since herdr sessions survive detaching.
- `initial-command` runs herdr in the first window only, so new windows are plain shells. Delete that line if you'd rather launch it by hand.

**herdr** (`~/.config/herdr/config.toml`)
- Your gruvbox theme is kept.
- The agent panel sorts by priority, so agents that need you rise to the top.
- Agent labels show on pane borders.
- macOS notifications fire when an agent needs you.
- **Claude Code integration installed.** herdr can now track Claude's state (working, blocked, done). This added a hook at `~/.claude/hooks/herdr-agent-state.sh` and updated `~/.claude/settings.json`, so it touches your Claude config.

## Keybinds

The default prefix is `ctrl+b`, followed by a key. I added direct `ctrl+alt` chords, which work in Ghostty on macOS even though plain Option combos don't. The prefix versions still work too.

| Action | Keys |
|---|---|
| Focus pane left, down, up, right | `ctrl+alt+h/j/k/l` |
| Last pane | `ctrl+alt+;` |
| Zoom pane | `ctrl+alt+z` |
| Split right / split down | `ctrl+alt+d` / `ctrl+alt+shift+d` |
| Close pane | `ctrl+alt+w` |
| New tab | `ctrl+alt+c` |
| Previous / next tab | `ctrl+alt+[` / `ctrl+alt+]` |
| Previous / next agent | `ctrl+alt+,` / `ctrl+alt+.` |
| Focus agent 1–9 | `ctrl+alt+1..9` |
| Workspace 1–9 | `ctrl+alt+shift+1..9` |
| Jump to the agent that needs you | `ctrl+alt+o` |
| Session navigator | `ctrl+alt+g` |

## Learning order

1. Run `prefix+?` inside herdr to see every active binding.
2. Start with focus (`ctrl+alt+hjkl`), then zoom and split.
3. Then `ctrl+alt+o`, which jumps straight to whichever agent is waiting on you.
4. Add agent-number jumps once you regularly have three or more agents running.

## Caveats

- I couldn't test the chords in a live terminal. If one doesn't fire, run `prefix+?` to see whether herdr received it. If it didn't, Ghostty or macOS probably owns that chord.
- `ctrl+alt+shift+1..9` is the least certain combination. If it fails, change `workspaces` under `[keys.indexed]`.
- To apply changes without a restart, run `herdr server reload-config`, or press `prefix+shift+r` inside herdr.
- Don't run `herdr` inside a herdr pane. It refuses to nest.
- Quit and reopen Ghostty to pick up its config, or press `cmd+shift+,`.

If you use Codex or another agent, `herdr integration install <name>` does the same for it. Tell me which ones.
