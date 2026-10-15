# Remote workspaces

How (and how little) to carry these dotfiles into remote, employer-managed development workspaces.
Written for humans and for agents doing the setup. Read [../AGENTS.md](../AGENTS.md) first.

## Principle: a thin, read-only bridge

The remote is not a second home for this config. It's a **read-only consumer** of the portable parts.

- Changes flow one way: edit locally, push here, the remote pulls. Nothing is committed from a remote.
- **This repo is the only source of truth.** Nothing is created on, hosted by, or registered with the employer's
  systems. If the host offers its own dotfiles hook (typically an employer-hosted repo that is cloned and
  hard-reset into `$HOME`), it is deliberately left unused. That is a choice about ownership, not a technical
  limit.
- No personal credentials, personal git identity, or tokens go onto a remote. So the repo stays public and is
  cloned anonymously over HTTPS; making it private would force a credential onto the remote.
- Nothing from the employer's environment (hostnames, tool names, repo or workspace names, paths) comes back
  into this public repo. Employer-specific notes live in private notes outside the repo.
- Customization depth stays shallow on purpose: the prompt and a few shell niceties, nothing that changes how
  the employer's tooling behaves.

## What goes on a remote, and what never does

| Apply | Never apply |
|---|---|
| `dot_config/starship.toml` (prompt) | Ghostty config (runs on the laptop, not the remote) |
| `dot_config/zsh/90-prompt.zsh` | herdr config and `05-herdr.zsh` |
| `dot_config/zsh/85-pokeball.zsh` (glyph ball; no sprites remotely) | Pokemon background, sprites, `scripts/` |
| | `10-aliases.zsh`, `20-tools.zsh` (remote has its own version managers), `30-plugins.zsh` (Homebrew paths) |
| | Anything under `archive/` |

This is enforced, not just documented: `.chezmoiignore` is **default-deny** for the `remote` profile, so a new
tool added to the repo later stays off remotes until it is explicitly allowed there. Test any change with
`chezmoi managed --config <remote.toml> --destination <tmpdir>`. Note `.config/**` is the wrong pattern (it also
matches `.config` itself and ignores everything); use single-level `.config/*` plus `!` exceptions.

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
        run scripts/remote-bootstrap.sh on the workspace, at the exact pushed commit
remote: install chezmoi + starship to ~/.local/bin   (pinned versions, SHA-256 verified)
        chezmoi init + guard + apply                 (profile = remote, allow-list enforced twice)
        append a marked loader block to ~/.zshrc
refresh: re-run the same script (idempotent). New workspaces need one run each; nothing runs automatically.
```

A per-machine, **untracked** `~/.config/chezmoi/chezmoi.toml` on the remote sets `[data] profile = "remote"`, and the
templated `.chezmoiignore` then applies only the allow-list above. The laptop keeps the default profile.

Remote bootstrap conventions: pin tool versions and verify SHA-256 against pinned values; isolate git from the
host's global config for the clone (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_TERMINAL_PROMPT=0`) so no employer
identity or credential helper is involved; append the loader to `~/.zshrc` between marker comments so it is
idempotent and trivially removable; always exit 0 and keep an opt-out file.

## Ask the user before

- creating a repo on any employer-managed host, or changing employer tooling configuration;
- installing anything on a remote, or running anything beyond read-only inspection there;
- adding any file to this repo that came from a remote or mentions employer systems;
- expanding the "Apply" column.

`scripts/remote-bootstrap.sh` enforces the allow-list itself (`ALLOWED_FILES`), independent of `.chezmoiignore`:
if the repo would apply anything else, it refuses and applies nothing. When the allow-list changes, update both.
Run it from the laptop with a small helper kept in the (untracked, work-specific) local `~/.zshrc` that executes
the script at the pushed commit through an existing connection to the workspace.

## Log: what we've learned

Append dated notes here as the setup teaches us something. Keep them generic.

- 2026-10-13 (later): default-deny `remote` profile verified by dry run (laptop 10 files, remote 3, a simulated new
  tool did not leak). The remote lacked the `xterm-ghostty` terminfo and had `~/.local/bin` off `PATH` in
  non-login shells, so the loader exports `PATH` itself. Remote prompts may show a clock twice if the host's stock
  config sets `RPROMPT`.
- 2026-10-13: a remote workspace had a stock zsh config (not managed), a writable home, GitHub reachable,
  neither starship nor chezmoi installed, and no dotfiles repo configured. The host supports a dotfiles repo that
  is checked into `$HOME` as a bare repo with a hard reset on resume, which is why this repo's loader approach
  avoids tracking `.zshrc`.
- 2026-10-15: the first design put a thin bootstrap repo on the employer's git host so the host's hook would run it
  on every start. Rejected: the goal is for this repo to be the only source of truth. The bootstrap script now lives
  here and is run by hand, trading automatic setup of new workspaces for sole ownership.
