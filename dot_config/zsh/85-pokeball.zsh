# A different Pokeball before each prompt. Starship has one env_var module per ball in
# ~/.config/starship.toml (tinted per type); exactly one STARSHIP_BALL_<NAME> is set per prompt.
#
# Two display modes:
#   sprite - the real ball icon as an inline image (kitty graphics protocol), if the sprites were
#            downloaded with scripts/pokeball-sprites.sh. Starship prints the placeholder @@BALL@@ and
#            95-pokeball-sprites.zsh swaps in the image at display time.
#   glyph  - Nerd Font glyph U+F041D, tinted. The fallback.
# Force the glyph with POKEBALL_SPRITES=0.
typeset -ga _pokeballs=(poke great ultra master premier luxury dusk heavy level lure moon friend love
                        fast timer repeat net nest dive quick safari sport cherish park heal dream)
typeset -g _pokeball_dir="${POKEBALL_DIR:-$HOME/.local/share/pokeballs}"

_pokeball_precmd() {
  local b
  for b in $_pokeballs; do unset "STARSHIP_BALL_${(U)b}"; done
  b=${_pokeballs[RANDOM % $#_pokeballs + 1]}
  export STARSHIP_BALL_NAME=$b
  if [[ ${POKEBALL_SPRITES:-1} != 0 && $TERM_PROGRAM == (ghostty|herdr) && -r $_pokeball_dir/$b.seq ]]; then
    # %{ %} makes the image escape zero-width for zsh; the two spaces are the cells the image covers.
    typeset -g _POKEBALL_SEQ="%{$(<$_pokeball_dir/$b.seq)%}  "
    export "STARSHIP_BALL_${(U)b}"='@@BALL@@'
  else
    typeset -g _POKEBALL_SEQ=
    export "STARSHIP_BALL_${(U)b}"="${POKEBALL_GLYPH:-$'\U000f041d'}"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _pokeball_precmd

# `ball` prints the ball in the current prompt; `ball list` prints every type.
ball() { [[ $1 == list ]] && print -l $_pokeballs || print $STARSHIP_BALL_NAME; }
