# Setup guide

How to get these dotfiles running on a machine from a blank slate, by hand or with an AI agent. Written to work on
any system: a personal laptop, a work laptop, or a machine you don't own. Nothing here depends on an employer.

## Choose your path

- **Setting up by hand?** Read "Supported systems", then follow Part 1 (a full laptop) or Part 2 (a prompt-only machine).
- **Using an AI agent?** Skip to [Part 5: For AI agents](#part-5-for-ai-agents). It says what to read, what the agent may
  do alone, and where it must stop and ask you.

## Supported systems

| System | Profile | What you get | Status |
|---|---|---|---|
| macOS laptop | default | Ghostty, herdr, zsh modules, starship prompt with a Pokeball and git details | Tested |
| Linux x86_64 (a server, a remote dev box, a work machine) | `remote` | **Only** the prompt: 3 files + one block in `~/.zshrc` | Tested on Ubuntu 22.04 |
| Linux laptop | default or `remote` | The default profile applies, but some config assumes macOS (Homebrew paths in `30-plugins.zsh`, the Option-key setting in Ghostty). Use `remote` unless you adapt it | Untested |
| Anything else (ARM Linux, BSD, Windows) | none | `remote-bootstrap.sh` exits with "unsupported platform" and changes nothing | Untested |

The two profiles are one repo with one switch: a per-machine, untracked `~/.config/chezmoi/chezmoi.toml` containing
`[data] profile = "remote"`. Without it you get the default (full) profile.

## Principles

1. **This repo is the only source of truth.** Machine-specific or employer-specific things never go in it; they live in the
   machine's own untracked `~/.zshrc` (see Part 3).
2. **Nothing the host provisions is replaced.** `~/.zshrc`, `~/.zprofile` and `~/.gitconfig` are never tracked. The only
   edit to a host file is one appended, marked, removable block in `~/.zshrc`.
3. **A prompt-only machine is a read-only mirror.** Edit on your main machine, push, then refresh there. Never commit from it.
4. **Keep it shallow.** The `remote` profile applies exactly 3 files, enforced twice (see Part 2).

---

## Part 1: A full laptop (macOS), by hand

```sh
# 1. Tools
brew install chezmoi starship zsh-autosuggestions zsh-syntax-highlighting herdr
brew install --cask ghostty font-hack-nerd-font

# 2. Pull and apply (anonymous HTTPS; the repo is public). Applies 10 files.
chezmoi init --apply nio-not-neo/dotfiles

# 3. Add one line at the END of ~/.zshrc, so the prompt initialises last
for f in ~/.config/zsh/*.zsh(N); do source "$f"; done; unset f

# 4. Optional: let herdr track Claude Code sessions (adds a hook under ~/.claude)
herdr integration install claude

# 5. Optional, per machine: artwork is fetched, never committed
cd "$(chezmoi source-path)"        # `chezmoi cd` opens a subshell, so don't chain it
scripts/pokeball-sprites.sh        # real Pokeball sprites in the prompt (else a tinted glyph)
scripts/pokemon-bg.sh blaziken     # Ghostty background; also: deoxys | <dex 1-719> | off

# 6. Optional: see agents running on other machines in the same herdr window
herdr machine add <ssh-host> --label <name>   # asks before installing herdr on that machine
```

Remote agents are only seen if they run in a pane of the *remote* herdr (not a plain ssh terminal), and a wrapper
command needs `HERDR_AGENT=<engine>` set there too: see the troubleshooting table. Wrapper functions are
machine-specific, so keep them in that machine's own untracked shell config (Part 3), never in this repo.

Quit and reopen Ghostty (a config reload does not re-run the launch command). New windows attach to the herdr session.
Check with `chezmoi verify` (silent means in sync), `starship print-config >/dev/null` (never bare `starship config`: it
opens an editor and hangs), `ghostty +validate-config` and `herdr config check`.

## Part 2: A prompt-only machine (Linux x86_64), by hand

Use this for any machine where you want the prompt and nothing else: a server, a remote dev environment, a machine whose
configuration someone else manages.

```sh
# Pin the exact commit, and read the script before running it
COMMIT=$(git ls-remote https://github.com/nio-not-neo/dotfiles.git refs/heads/main | cut -f1)
curl -fsSL "https://raw.githubusercontent.com/nio-not-neo/dotfiles/$COMMIT/scripts/remote-bootstrap.sh" | less
curl -fsSL "https://raw.githubusercontent.com/nio-not-neo/dotfiles/$COMMIT/scripts/remote-bootstrap.sh" | bash
exec zsh
```

The script runs as your user, with no `sudo`, and:

1. Installs pinned `chezmoi` and `starship` into `~/.local/bin`, verifying each tarball's SHA-256 (a mismatch is refused).
2. Writes `~/.config/chezmoi/chezmoi.toml` with `profile = "remote"` (first run only; never overwrites yours).
3. Clones the repo over anonymous HTTPS, **isolated from the machine's own git config**, and refuses to apply anything
   outside the 3 allowed files, whatever the repo says (`ALLOWED_FILES` in the script, plus the default-deny
   `.chezmoiignore`). Change one, change both.
4. Appends one block to `~/.zshrc` between `# >>> personal-dotfiles >>>` markers (adds `~/.local/bin` to `PATH`, then
   sources `~/.config/zsh/*.zsh`).

It exits 0 on every path, so it can never break a shell. On this profile the expensive git modules (`git_status`,
`git_metrics`) are off: in a very large monorepo they cost ~700ms per prompt (measured 780ms with them, ~65ms without).

**Refresh:** `bash ~/.local/share/chezmoi/scripts/remote-bootstrap.sh` (idempotent).
**Opt out:** `touch ~/.no-personal-dotfiles`.
**Undo:** delete the marked block in `~/.zshrc`, then remove `~/.local/bin/{chezmoi,starship}`, `~/.local/share/chezmoi`,
`~/.config/chezmoi`, `~/.config/starship.toml` and `~/.config/zsh`.

## Part 3: Keep machine-specific things out of the repo

Anything that only makes sense on one machine, or that belongs to an employer, goes in that machine's own **untracked**
`~/.zshrc`, above the loader line. Typical examples: aliases for a company CLI, a wrapper for a work tool, a helper that
runs the Part 2 script on another machine through whatever remote-execution tool you have. Because the repo is public,
treat it as a rule that nothing identifying an employer, a host, or a colleague is ever committed here. If you want those
notes written down, keep them somewhere private and point to them from your own notes.

## Part 4: Maintaining it without crossing wires

The flow is one-way: **edit on your main machine, `git push`, then refresh the prompt-only machines** (Part 2's refresh).

- The clone lives at `~/.local/share/chezmoi`. Its remote is this repo over anonymous HTTPS with no push credentials.
- A prompt-only machine usually carries a *different* global git identity (an employer's, for instance). So an accidental
  push would almost certainly fail, but a **commit made in that clone would carry the wrong identity**. Don't commit there.
  Check what it would use: `git -C ~/.local/share/chezmoi config user.email`.
  The bootstrap script now enforces this: it sets an invalid push URL and placeholder identity in that clone and installs
  `pre-commit`/`pre-push` hooks that refuse, so a commit or push there fails loudly. Fetching (the refresh) still works.
- Don't run `gh` or other forge tools there either: they may point at a different host than this repo.
- `starship.toml` is a chezmoi template (it switches modules off per profile). Edit it with `chezmoi edit`, never
  `chezmoi re-add`, which would flatten the template. Everything else: edit the live file, then `chezmoi re-add`.

## Part 5: For AI agents

You are picking up this setup. Don't infer; read, then follow.

**Read first, in order** (public, no auth, under `https://raw.githubusercontent.com/nio-not-neo/dotfiles/main/`):
1. `AGENTS.md`: the hard rules. They override this page.
2. `docs/remote-workspaces.md`: the design for prompt-only machines, the allow-list, and a dated log of lessons.
3. `docs/zsh.md`, `docs/ghostty-customization.md`, `docs/ghostty-herdr.md`: per-tool detail.
4. `scripts/remote-bootstrap.sh`: read it before running it anywhere. It is the only code that ever executes on a
   machine you don't fully control, and it is pinned and checksum-verified.

**Check state first, read-only:** `git -C ~/.local/share/chezmoi log --oneline -5` (other sessions commit here, so don't
assume the tree matches your memory), `chezmoi verify`, `git status -sb`. On a machine you'll modify, record a "before":
hashes of `~/.zshrc`, `~/.profile`, `~/.gitconfig`, and the contents of `~/.local/bin`.

**You may do alone:** read files and docs; follow Part 1 on a fresh laptop the user pointed you at; edit a live file then
`chezmoi re-add` it (templates: `chezmoi edit`); validate configs; test with a throwaway home
(`HOME=$(mktemp -d) chezmoi init --apply nio-not-neo/dotfiles`); commit locally.

**Always stop and ask first:**
- `git push`. The user approves each push individually, by saying "push".
- running anything on another machine beyond read-only inspection;
- creating any repo, hook, gist or configuration on a system owned by a third party (an employer, a service) to deliver
  these dotfiles: this repo is the sole source of truth, so if a design seems to need one, stop;
- widening the 3-file allow-list (both places);
- anything that would put credentials or a personal identity on a machine that isn't the user's own.

**Human-only steps:** logins and VPN, approving pushes, and deciding whether the repo should be private (it is public on
purpose: private would force a credential onto every machine).

**Never:** commit secrets or anything identifying an employer, a host or a colleague; overwrite `~/.zshrc`, `~/.zprofile`
or `.gitconfig`; run unpinned scripts through a shell; commit from a prompt-only machine's clone.

**Verify after any change on another machine** (read-only) against your "before":
- the stock `~/.zshrc` (all lines above the marked block), `.profile` and `.gitconfig` hash identically;
- exactly one `personal-dotfiles` block in `~/.zshrc`;
- `~/.local/bin/chezmoi managed --include=files` lists only `.config/starship.toml`, `.config/zsh/85-pokeball.zsh`,
  `.config/zsh/90-prompt.zsh`;
- the prompt renders in under ~150ms in the largest repo on that machine (`starship prompt`, `starship timings`).

**Measure before you call a prompt change done.** Disabling one slow module can just move the cost to the next one, so
disable the whole family and A/B test without writing to the machine (pipe a script over stdin and use process
substitution for `STARSHIP_CONFIG`).

**Environment-specific details are not in this repo.** If the user says there are private notes for the environment you're
in (an employer's tooling, say), ask where they are and read them too. Append only dated, *generic* lessons to the log at
the bottom of `docs/remote-workspaces.md`.

## Appendix: Troubleshooting

| Symptom | Cause and fix |
|---|---|
| herdr lists some agents on a remote machine but not others | herdr only sees agents in panes of the remote herdr, and only recognises engines it knows by process name. A wrapper-launched engine needs `HERDR_AGENT=<engine>` set on that machine too (a function in its own `~/.zshrc`) |
| herdr does not list an agent that runs through a wrapper command | herdr sees the wrapper as the foreground process. Launch it with `HERDR_AGENT=<engine>` set (for example in a shell function) |
| herdr's sidebar shows `claude`, not the session name | Normal: it shows the agent type. The session name is the terminal title. Add a `terminal_title_stripped` row under `[ui.sidebar.agents.rows_by_agent]` |
| herdr does not launch in a new window | `initial-command` covers only the first surface; this setup launches it from `05-herdr.zsh`. Skip it with `NO_HERDR=1 zsh` |
| Pokeball stretched or sitting low | Sprites need an exact 2x1 cell box (`c=2,r=1`). Compare outside herdr with `NO_HERDR=1 zsh`; force the glyph with `POKEBALL_SPRITES=0` |
| Slow shell startup | nvm sourced eagerly (~1s). The repo lazy-loads it; profile with `zmodload zsh/zprof` |
| Slow prompt in a huge repo | `git_status`/`git_metrics` scan the working tree. The `remote` profile turns them off |
| `starship config` hangs | It opens an editor. Use `starship print-config` |
| Odd colors or backspace over ssh | The remote may lack the `xterm-ghostty` terminfo. Check `TERM` first |
| Nothing changed after the script ran | Open a new shell or `exec zsh`; confirm the marked block is in `~/.zshrc` and `~/.local/bin` is on `PATH` |
