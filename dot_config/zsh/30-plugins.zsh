# Plugins installed via Homebrew (brew install zsh-autosuggestions zsh-syntax-highlighting).
# zsh-syntax-highlighting must be sourced last among plugins.
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  f="${HOMEBREW_PREFIX:-/opt/homebrew}/share/$p/$p.zsh"
  [[ -r $f ]] && source "$f"
done
unset p f
