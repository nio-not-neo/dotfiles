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
| `20-tools.zsh` | nvm (lazy-loaded) and pyenv, each guarded so a missing tool doesn't break startup |
| `30-plugins.zsh` | zsh-autosuggestions and zsh-syntax-highlighting from Homebrew. Highlighting loads last |
| `90-prompt.zsh` | `starship init`. Last, so nothing re-initialises over it |

## Startup time

Eagerly sourcing nvm cost about 1s per shell (`nvm_auto` runs `nvm use` every time). The default node's
`bin` goes straight on `PATH` and nvm loads on the first `nvm` call. Startup went from ~1.4s to ~0.4s.
If the default alias isn't a plain version (such as `lts/*`), it falls back to eager loading.
Profile with `zmodload zsh/zprof` at the top of `~/.zshrc` and `zprof` at the bottom.

## Why no oh-my-zsh

Starship owns the prompt, and the two plugins above cover the parts of oh-my-zsh actually used.
Sourcing plugins directly avoids the framework's startup cost. If a plugin is needed later, add
it as another numbered module.

## Starship

`dot_config/starship.toml` is tracked as-is. About 150 lines are Nerd Font icon overrides.
Ghostty bundles Nerd Font symbols, so they render without installing a font.
The custom parts: command duration over 10s, git status emoji, memory usage over 70%, a clock.

## Git-aware prompt

The prompt line is ordered path, worktree, branch, detached commit and tag, in-progress state
(rebase/merge), line deltas, then file status (modified, staged, untracked, stashed, ahead/behind).

- **Worktree:** starship has no worktree module, so `[custom.git_worktree]` shows `🌳 name` only inside a
  linked `git worktree` (when `git rev-parse --git-dir` differs from `--git-common-dir`). Plain clones stay clean.
  Costs two quick `git` calls per prompt.
- **Line deltas:** `git_metrics` shows `+added -deleted` for the working tree.
- Test changes with `starship prompt --path <dir>`. Use `starship print-config` to validate: bare
  `starship config` opens an editor and hangs.

## Bootstrap

```sh
brew install starship zsh-autosuggestions zsh-syntax-highlighting
chezmoi init --apply nio-not-neo/dotfiles
# then add the loader line above to ~/.zshrc
```

## Adding something new

- Portable and safe to publish: add or edit a module in `~/.config/zsh/`, then `chezmoi add` it.
- Work-specific or machine-specific: put it in the local `~/.zshrc`. Never commit it.
