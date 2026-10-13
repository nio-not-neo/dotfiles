# Remote workspaces

How (and how little) to carry these dotfiles into remote, employer-managed development workspaces.
Written for humans and for agents doing the setup. Read [../AGENTS.md](../AGENTS.md) first.

## Principle: a thin, read-only bridge

The remote is not a second home for this config. It's a **read-only consumer** of the portable parts.

- Changes flow one way: edit locally, push here, the remote pulls. Nothing is committed from a remote.
- No personal credentials, personal git identity, or tokens go onto a remote.
- Nothing from the employer's environment (hostnames, tool names, repo or workspace names, paths) comes back
  into this public repo. Employer-specific notes live in private notes outside the repo.
- Customization depth stays shallow on purpose: the prompt and a few shell niceties, nothing that changes how
  the employer's tooling behaves.

## What goes on a remote, and what never does

| Apply | Never apply |
|---|---|
| `dot_config/starship.toml` (prompt) | Ghostty config (runs on the laptop, not the remote) |
| `dot_config/zsh/90-prompt.zsh` | herdr config and `05-herdr.zsh` |
| Optionally `10-aliases.zsh` | Pokemon background, sprites, `scripts/` |
| | `20-tools.zsh` (remote has its own version managers), `30-plugins.zsh` (Homebrew paths) |
| | Anything under `archive/` |

The terminal (Ghostty, fonts, images) always runs on the laptop, so Nerd Font glyphs render remotely without
installing anything there. The Pokeball falls back to the tinted glyph, because the sprite files are per machine.

## Nuances to respect

1. **Linux, not macOS.** No Homebrew paths, no `/opt/homebrew`, no Mac-only commands. Guard anything portable.
2. **The host may own your home directory files.** Some workspace tooling checks a dotfiles repo straight into
   `$HOME` and hard-resets it on resume, which silently overwrites tracked files such as `.zshrc` and
   `.gitconfig`. So never claim those files. Add one guarded loader line instead (see `docs/zsh.md`).
3. **Setup scripts are constrained.** They typically run as the user (not root), may have no forwarded SSH key,
   and run either once at creation or on every start. Use HTTPS to a public repo, and make them idempotent.
4. **Workspaces are paused and recreated.** Bootstrap must be repeatable and **fail soft**: short network
   timeouts, and a failed update must leave the shell usable with the previous config.
5. **User-level installs only.** Binaries go to `~/.local/bin`. No `sudo`, no system packages from this repo.
6. **Preserve what the stock setup shows.** The default prompt may display the workspace name from an env var.
   The starship config shows it through an `env_var` module so it isn't lost, and the module is hidden where the
   variable is unset, so it doesn't affect the laptop.
7. **No secrets, ever.** Automated scanners flag tokens in dotfiles. Scan before every push.
8. **Pin what you download.** Fetch installers or artwork by pinned version or commit, and verify file type
   before use. Never pipe an unpinned script into a shell.

## Setup shape (the design, not a runbook)

```
laptop: edit -> git push (this repo)
remote: bootstrap (once)  -> install chezmoi + starship to ~/.local/bin
                          -> chezmoi init --apply <this repo>   (profile = remote)
        on every start    -> chezmoi update   (timeout, fail soft)
```

A per-machine, **untracked** `~/.config/chezmoi/chezmoi.toml` on the remote selects a `remote` profile, and a
templated `.chezmoiignore` excludes everything in the "never" column. The laptop keeps the default profile.

## Ask the user before

- creating a repo on any employer-managed host, or changing employer tooling configuration;
- installing anything on a remote, or running anything beyond read-only inspection there;
- adding any file to this repo that came from a remote or mentions employer systems;
- expanding the "Apply" column.

## Log: what we've learned

Append dated notes here as the setup teaches us something. Keep them generic.

- 2026-10-13: a remote workspace had a stock zsh config (not managed), a writable home, GitHub reachable,
  neither starship nor chezmoi installed, and no dotfiles repo configured. The host supports a dotfiles repo that
  is checked into `$HOME` as a bare repo with a hard reset on resume, which is why this repo's loader approach
  avoids tracking `.zshrc`.
