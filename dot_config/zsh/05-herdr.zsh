# Attach to the persistent herdr session whenever a new interactive shell starts in Ghostty.
# Done here rather than via Ghostty's `command`/`initial-command`: that applies only at surface/app
# launch and was unreliable across config reloads. Skips when:
#   - not in Ghostty (SSH sessions, VS Code, other terminals) or not a real terminal
#   - already inside herdr (HERDR_ENV is set in every herdr pane; herdr also refuses to nest)
#   - herdr isn't installed, or NO_HERDR=1 is set (escape hatch: NO_HERDR=1 zsh)
# herdr runs as a normal child, so detaching (prefix+q) or a failed start drops you into this shell.
if [[ -o interactive && -t 0 && -t 1 && $TERM_PROGRAM == ghostty && -z $HERDR_ENV && -z $NO_HERDR ]] \
   && (( $+commands[herdr] )); then
  herdr
fi
