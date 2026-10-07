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
| `05-herdr.zsh` | Auto-attach to herdr in new Ghostty shells (see [ghostty-customization.md](ghostty-customization.md)) |
| `10-aliases.zsh` | General-purpose aliases |
| `20-tools.zsh` | nvm (lazy-loaded) and pyenv, each guarded so a missing tool doesn't break startup |
| `30-plugins.zsh` | zsh-autosuggestions and zsh-syntax-highlighting from Homebrew. Highlighting loads last |
| `85-pokeball.zsh` | Picks a random Pokeball before each prompt (see below) |
| `90-prompt.zsh` | `starship init` |
| `95-pokeball-sprites.zsh` | Swaps the ball placeholder for the sprite image. Must load after the prompt |

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
- The worktree marker shows the repo the worktree belongs to (`🌳 main-repo`), since the directory module already
  shows the worktree folder.
- Test changes with `starship prompt --path <dir>`. Use `starship print-config` to validate: bare
  `starship config` opens an editor and hangs.

## Two-line layout and the Pokeball

Line 1 is the path plus git details. Line 2 is `╰─`, the clock, a ball and the prompt character, so the arrow sits
where you type. Starship excludes any module named explicitly in `format` from `$all`, which is how line 2 stays on
line 2.

The ball changes on every prompt. No Unicode emoji exists for a Pokeball, so this uses the Nerd Font glyph
`U+F041D`: one shape, tinted per ball type (26 types, e.g. Great = blue, Ultra = yellow, Dusk = dark green).
A `precmd` hook in `85-pokeball.zsh` exports exactly one `STARSHIP_BALL_<NAME>`, and starship has one `env_var`
module per ball. This spawns no extra processes. `ball` prints the current type, `ball list` prints all of them.

### Sprite mode

With the sprites installed, the ball is the real icon, drawn inline with the kitty graphics protocol (Ghostty
supports it, and herdr passes pane images through to it). Each of the 26 balls has its own design, all in one
consistent style, from PokeAPI's item sprites, not a tinted glyph.

```sh
scripts/pokeball-sprites.sh        # download + convert (pinned commit, validates each file is a PNG)
scripts/pokeball-sprites.sh off    # remove them; the prompt falls back to the glyph
POKEBALL_SPRITES=0 zsh             # one-off: force the glyph in this shell
```

How it works, and why it's built this way:

- **Starship can't carry the image.** It doubles every `%` and only recognises colour escapes, so a raw image
  escape corrupts zsh's idea of the prompt width. Starship prints a plain placeholder (`@@BALL@@`) instead.
- **zsh swaps it in at display time** (`95-pokeball-sprites.zsh` rewrites `$PROMPT`). The replacement is wrapped in
  `%{ %}` (zero width) and followed by two real spaces, which the image covers. `C=1` keeps the cursor still and
  `q=2` suppresses terminal replies that would otherwise land in your input.
- **Sprites are fetched per machine, not committed.** The artwork isn't ours to redistribute.
- **Fallback is automatic** when the sprites are missing, or the terminal isn't Ghostty/herdr.

Not the Gen 3 capture-animation art: no fetchable source of those exists, so these are the closest era-consistent
icons. Swap files in `~/.local/share/pokeballs/<name>.seq` if you have artwork you prefer.

## Bootstrap

```sh
brew install starship zsh-autosuggestions zsh-syntax-highlighting
chezmoi init --apply nio-not-neo/dotfiles
scripts/pokeball-sprites.sh        # optional: sprite balls (run from the repo: chezmoi cd)
# then add the loader line above to ~/.zshrc
```

## Adding something new

- Portable and safe to publish: add or edit a module in `~/.config/zsh/`, then `chezmoi add` it.
- Work-specific or machine-specific: put it in the local `~/.zshrc`. Never commit it.
