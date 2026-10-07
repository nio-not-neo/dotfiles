# dotfiles

Personal configuration, managed with [chezmoi](https://www.chezmoi.io/). Built up over time as I learn and settle into tools.

## Bootstrap a new machine

```sh
brew install chezmoi
chezmoi init --apply nio-not-neo/dotfiles
```

## Layout

chezmoi maps this repo onto `$HOME`: `dot_config/foo` becomes `~/.config/foo`.

| Path | Purpose |
|---|---|
| `dot_config/<tool>/` | Active, applied config for each tool |
| `docs/<tool>.md` | Why it's set up that way, keybinds, caveats, learning notes |
| `archive/<tool>/` | Not applied. Settings and ideas from tools I've moved on from (iTerm2, Warp, kitty, fish) to mine for migration |
| `.chezmoiignore` | Files that shouldn't be applied on every machine or OS |

## Tools

| Tool | Config | Notes |
|---|---|---|
| [Ghostty](https://ghostty.org) | `dot_config/ghostty/` | Terminal emulator |
| [herdr](https://herdr.dev) | `dot_config/herdr/` | Workspace/agent manager. See [docs/ghostty-herdr.md](docs/ghostty-herdr.md) |
| zsh | `dot_config/zsh/` | Modular config sourced from a local `~/.zshrc`. See [docs/zsh.md](docs/zsh.md) |
| [Starship](https://starship.rs) | `dot_config/starship.toml` | Prompt |

## Adding a new tool

```sh
chezmoi add ~/.config/<tool>/<file>     # start tracking
chezmoi edit ~/.config/<tool>/<file>    # edit the source copy
chezmoi diff && chezmoi apply           # preview, then apply
chezmoi cd                              # jump into this repo to commit and push
```

Then add a row to the table above and a `docs/<tool>.md` note.

## Conventions

- **No secrets, no employer-specific config.** The repo is public. Machine-specific bits go in templates (`.tmpl`) or `.chezmoiignore`.
- **Document the why.** A config without a note on why it exists is hard to migrate later.
- **Retired tools go to `archive/`**, not the trash. Their settings are raw material for the next tool.

## Planned

- [ ] mine `archive/` for iTerm2, Warp, kitty and fish settings worth bringing into Ghostty
- [ ] revisit the 2024 checklist in `archive/README-2024-original.md` (micro, asdf, VS Code) and port `archive/bash/` ideas (aliases, PATH setup) to zsh
