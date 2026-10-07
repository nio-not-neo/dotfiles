# Ghostty customization

Changes layered on the original setup in [ghostty-herdr.md](ghostty-herdr.md), mostly carried over from
iTerm2 and Warp (see `archive/`).

| Setting | Why |
|---|---|
| `font-family = "Hack Nerd Font"` | Your iTerm2 font. Matches the Nerd Font icons in the starship config |
| `keybind = shift+enter=text:\n` | Newline without submitting, for multi-line input in Claude Code and the shell |
| `notify-on-command-finish = unfocused`, `after = 30s` | Ordinary long commands (builds, tests). herdr covers agent notifications |
| `config-file = ?pokemon.ghostty` | Optional per-machine Pokemon background (below) |

## Pokemon background

[Pokemon-Terminal](https://github.com/LazoVelko/Pokemon-Terminal) doesn't support Ghostty: it drives
iTerm2/Kitty-style background APIs, so `pokemon -n deoxys` does nothing here. Instead,
`scripts/pokemon-bg.sh` downloads that project's artwork (pinned to a commit) and writes
`~/.config/ghostty/pokemon.ghostty`, which uses Ghostty's native `background-image` at 20% opacity so text
stays readable. The image and generated snippet are **not tracked**: the artwork isn't ours to redistribute.

```sh
scripts/pokemon-bg.sh blaziken    # default; also: deoxys | attack | defense | speed | <dex 1-719> | off
```

Reload with `cmd+shift+,`. The art set covers Gen I-VI only, so Gen VII+ (e.g. Ceruledge, #937) has no image.
If a background hurts legibility, lower `background-image-opacity` in the generated file.
