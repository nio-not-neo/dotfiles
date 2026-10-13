#!/usr/bin/env bash
# Download Pokeball sprites and convert them into ready-to-print kitty-graphics sequences for the prompt.
#
# Source: PokeAPI/sprites (item icons), pinned to a commit. One consistent style across all 26 balls.
# The artwork is not ours to redistribute, so it is fetched per machine and never committed.
# Output: ~/.local/share/pokeballs/<name>.seq (each file is a complete escape sequence, printed as-is)
#
# Usage: scripts/pokeball-sprites.sh [install|off]
set -euo pipefail

REPO="PokeAPI/sprites"
REF="d72f64eb74912747cb5c5579061ced4842ba0a98"   # pinned commit
OUT="${POKEBALL_DIR:-$HOME/.local/share/pokeballs}"
# Must match _pokeballs in dot_config/zsh/85-pokeball.zsh and the env_var modules in starship.toml
BALLS=(poke great ultra master premier luxury dusk heavy level lure moon friend love
       fast timer repeat net nest dive quick safari sport cherish park heal dream)

case "${1:-install}" in
  off) rm -rf "$OUT"; echo "removed $OUT (prompt falls back to the glyph ball)"; exit 0 ;;
  install) ;;
  *) echo "usage: $0 [install|off]" >&2; exit 1 ;;
esac

mkdir -p "$OUT"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
for b in "${BALLS[@]}"; do
  if ! curl -fsSL "https://raw.githubusercontent.com/$REPO/$REF/sprites/items/$b-ball.png" -o "$tmp/$b.png"; then
    echo "  missing: $b-ball" >&2; fail=$((fail+1)); continue
  fi
  # Must be a real PNG; refuse anything else before it reaches a terminal escape sequence.
  [[ "$(head -c 8 "$tmp/$b.png" | od -An -tx1 | tr -d ' \n')" == 89504e470d0a1a0a ]] \
    || { echo "  not a PNG: $b" >&2; fail=$((fail+1)); continue; }
  # a=T transmit+display, f=100 PNG, c=2,r=1 exactly two cells wide by one row (without r, the height is guessed and stretched),
  # C=1 don't move the cursor (the prompt prints two spaces under the image), q=2 suppress terminal replies.
  printf '\033_Ga=T,f=100,c=2,r=1,C=1,q=2;%s\033\\' "$(base64 < "$tmp/$b.png" | tr -d '\n')" > "$OUT/$b.seq"
done
echo "installed $(( ${#BALLS[@]} - fail ))/${#BALLS[@]} sprites in $OUT"
[[ $fail -eq 0 ]] || exit 1
echo "Open a new shell (or run: exec zsh). Disable per-shell with POKEBALL_SPRITES=0."
