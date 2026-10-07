# zsh + starship

## Approach

chezmoi does **not** own `~/.zshrc` or `~/.zprofile`. Those files stay local and untracked, because
they can contain machine-specific setup and tooling that edits them in place (for example employer
shell wrappers). Instead, chezmoi manages small modules in `~/.config/zsh/`, and the local
`~/.zshrc` loads them with one line at the end:

```zsh
for f in ~/.config/zsh/*.zsh(N); do source "$f"; done
```

Files load in alphabetical order, so the numeric prefixes set the order.

| Module | Purpose |
|---|---|
| `10-aliases.zsh` | General-purpose aliases |
| `20-tools.zsh` | nvm and pyenv, each guarded so a missing tool doesn't break startup |
| `30-plugins.zsh` | zsh-autosuggestions and zsh-syntax-highlighting from Homebrew. Highlighting loads last |
| `90-prompt.zsh` | `starship init`. Last, so nothing re-initialises over it |

## Why no oh-my-zsh

Starship owns the prompt, and the two plugins above cover the parts of oh-my-zsh actually used.
Sourcing plugins directly avoids the framework's startup cost. If a plugin is needed later, add
it as another numbered module.

## Starship

`dot_config/starship.toml` is tracked as-is. About 150 lines are Nerd Font icon overrides.
Ghostty bundles Nerd Font symbols, so they render without installing a font.
The custom parts: command duration over 10s, git status emoji, memory usage over 70%, a clock.

## Bootstrap

```sh
brew install starship zsh-autosuggestions zsh-syntax-highlighting
chezmoi init --apply nio-not-neo/dotfiles
# then add the loader line above to ~/.zshrc
```

## Adding something new

- Portable and safe to publish: add or edit a module in `~/.config/zsh/`, then `chezmoi add` it.
- Work-specific or machine-specific: put it in the local `~/.zshrc`. Never commit it.
