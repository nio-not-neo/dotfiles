# AGENTS.md

Guidance for AI agents working in this dotfiles repo. Humans: see [README.md](README.md).

## What this repo is

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). The source dir is `~/.local/share/chezmoi`;
`dot_config/foo` maps to `~/.config/foo`. The repo is **public**.

## Hard rules

1. **Public repo: nothing employer-specific.** No internal hostnames, tool or command names, repo or workspace
   names, internal URLs, usernames of colleagues, or paths. If a note needs those, keep it in private notes
   outside the repo and write a generic version here.
2. **This repo is the sole source of truth.** Never create repos, hooks or config on employer-managed systems to
   deliver these dotfiles, even where a documented mechanism exists. Remote setup is a script in this repo that the
   user runs. If a design seems to need an employer-hosted artifact, stop and ask.
3. **No secrets.** Scan for tokens, keys and credentials before every commit.
4. **Never overwrite files the host or an employer tool manages.** `~/.zshrc` and `~/.zprofile` stay local and
   untracked; the repo ships modules in `~/.config/zsh/*.zsh` that a one-line loader sources.
5. **Redistribution:** third-party artwork (Pokemon sprites and backgrounds) is fetched per machine by scripts,
   pinned to a commit, and never committed.
6. **Confirm before outward-facing or hard-to-reverse actions:** `git push`, creating repos, running anything on
   a remote machine beyond read-only inspection. The user has approved pushes one at a time.
7. **Keep customization shallow.** Prefer the smallest change. Don't deepen remote customization without asking.

## Workflow

- Edit the live file (`~/.config/...`), then `chezmoi re-add <file>` (tracked files) or `chezmoi add <file>`
  (new files). Verify with `chezmoi verify`.
- Validate before committing: `ghostty +validate-config`, `starship print-config` (never bare `starship config`:
  it opens an editor and hangs), `herdr config check`, `bash -n` on scripts.
- Check `git log` before editing: other sessions may have committed. Don't assume the tree matches your memory.
- Commit messages end with the attribution line the harness provides.
- Document the *why* in `docs/<tool>.md`; retired tools' settings go to `archive/<tool>/`, scrubbed.

## Where things are

| Path | What |
|---|---|
| `dot_config/ghostty`, `dot_config/herdr` | Terminal and workspace manager |
| `dot_config/zsh/*.zsh`, `dot_config/starship.toml` | Shell modules and prompt (two-line layout, Pokeball per prompt) |
| `scripts/` | Per-machine helpers (backgrounds, sprites). Not applied to `$HOME` |
| `docs/` | Per-tool notes. Start with `docs/remote-workspaces.md` for any remote work |
| `archive/` | Not applied. Settings from retired tools |

## Gotchas already hit

- `initial-command` in Ghostty only covers the first surface after launch.
- Starship `format` modules named explicitly are excluded from `$all`; that is how the second line stays put.
- Sprite images need an explicit `c=2,r=1` box or the terminal stretches them.
- herdr sees wrapper processes (not the agent under them); a `HERDR_AGENT` env hint fixes detection.
