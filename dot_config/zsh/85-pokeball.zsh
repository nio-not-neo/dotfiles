# A different Pokeball before each prompt. Starship has one env_var module per ball in
# ~/.config/starship.toml (same glyph, tinted per type); exactly one variable is set per prompt.
# Glyph: U+F041D (nf-md-pokeball), needs a Nerd Font.
typeset -ga _pokeballs=(poke great ultra master premier luxury dusk heavy level lure moon friend love
                        fast timer repeat net nest dive quick safari sport cherish park heal dream)

_pokeball_precmd() {
  local b
  for b in $_pokeballs; do unset "STARSHIP_BALL_${(U)b}"; done
  b=${_pokeballs[RANDOM % $#_pokeballs + 1]}
  export "STARSHIP_BALL_${(U)b}"=$'\U000f041d'
  export STARSHIP_BALL_NAME=$b
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _pokeball_precmd

# `ball` prints the ball in the current prompt; `ball list` prints every type.
ball() { [[ $1 == list ]] && print -l $_pokeballs || print $STARSHIP_BALL_NAME; }
