# Loads after 90-prompt.zsh. Starship only prints the placeholder @@BALL@@ (it escapes % and mangles
# raw terminal escapes); here the placeholder is replaced with the image sequence built by
# _pokeball_precmd. promptsubst runs this at every prompt draw, before % escapes are processed,
# so the %{ %} wrapper in $_POKEBALL_SEQ is honoured.
# Only rewrite once, and only when starship's prompt command is in place (it embeds the binary's
# full path, e.g. $(/opt/homebrew/bin/starship prompt ...), so match on the command, not a prefix).
if [[ $PROMPT == '$('*'starship prompt'* && $PROMPT != *@@BALL@@* ]]; then
  PROMPT='${'"$PROMPT"'//@@BALL@@/${_POKEBALL_SEQ}}'
fi
