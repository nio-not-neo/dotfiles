#!/usr/bin/env bash
# Walk one remote machine through the whole personal setup, one y/N prompt per step, skipping what is already done.
#
#   scripts/remote-setup.sh <ssh-host> [--label NAME] [--check]
#
# <ssh-host> is anything `ssh` accepts (a Host from ~/.ssh/config, user@host, ssh://...). Run it on your MAIN machine.
#   1. prompt     installs the prompt-only profile (pinned scripts/remote-bootstrap.sh at the current main commit)
#   2. hints      optional: appends YOUR agent-wrapper snippet to the remote ~/.zshrc as one marked block, so herdr can
#                 recognise agents started through a wrapper command. The snippet is a local, untracked file
#                 ($REMOTE_SETUP_HINTS, default ~/.config/remote-setup/agent-hints.zsh); nothing machine- or
#                 employer-specific ever lives in this repo. No file means the step is skipped.
#   3. herdr      `herdr machine add`, so the machine's agents show in your local herdr. Herdr asks before it installs
#                 itself on the remote.
# --check only reports status and changes nothing. Re-running is safe. Needs working, non-interactive-capable ssh.
set -u

REPO=nio-not-neo/dotfiles
HINTS="${REMOTE_SETUP_HINTS:-$HOME/.config/remote-setup/agent-hints.zsh}"
host="" label="" check=0
while [ $# -gt 0 ]; do
  case "$1" in
    --check) check=1 ;;
    --label) shift; label="${1:-}" ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) host="$1" ;;
  esac
  shift
done
[ -n "$host" ] || { echo "usage: $0 <ssh-host> [--label NAME] [--check]" >&2; exit 2; }
[ -n "$label" ] || label="${host%%.*}"

SOCK="${TMPDIR:-/tmp}/rs-$$"
rssh() { ssh -o ControlMaster=auto -o ControlPath="$SOCK" -o ControlPersist=120 "$host" "$@"; }
trap 'ssh -o ControlPath="$SOCK" -O exit "$host" >/dev/null 2>&1; true' EXIT

ask() { printf '%s [y/N] ' "$1"; read -r a; case "$a" in y|Y|yes) return 0 ;; *) return 1 ;; esac; }

p_prompt=? p_hints=? p_herdr=?
probe() {
  local out
  out=$(rssh bash -s 2>/dev/null <<'EOF'
grep -q ">>> personal-dotfiles >>>" ~/.zshrc 2>/dev/null && echo prompt=yes || echo prompt=no
grep -Eq ">>> agent-hints >>>|HERDR_AGENT" ~/.zshrc 2>/dev/null && echo hints=yes || echo hints=no
EOF
  ) || { echo "remote-setup: cannot reach '$host' over ssh (VPN, keys, or the connection tool for this host?). Fix plain 'ssh $host' first." >&2; return 1; }
  p_prompt=$(printf '%s\n' "$out" | sed -n 's/^prompt=//p')
  p_hints=$(printf '%s\n' "$out" | sed -n 's/^hints=//p')
  if command -v herdr >/dev/null 2>&1 && herdr machine list --json 2>/dev/null | grep -q "\"target\": \"$host\""; then p_herdr=yes; else p_herdr=no; fi
}
report() { printf '  %s: prompt=%s  agent-hints=%s  herdr-machine=%s\n' "$host" "$p_prompt" "$p_hints" "$p_herdr"; }

probe || exit 1
echo "remote-setup: status before"; report
[ "$check" = 1 ] && exit 0

# 1. prompt
if [ "$p_prompt" = yes ]; then echo "1/3 prompt: already done"
elif ask "1/3 Install the prompt-only setup on $host?"; then
  sha=$(git ls-remote "https://github.com/$REPO.git" refs/heads/main | cut -f1)
  [ -n "$sha" ] || { echo "could not resolve main commit" >&2; exit 1; }
  echo "running remote-bootstrap.sh @ ${sha%"${sha#????????????}"} on $host"
  rssh "curl -fsSL https://raw.githubusercontent.com/$REPO/$sha/scripts/remote-bootstrap.sh | bash"
else echo "1/3 skipped"; fi

# 2. agent hints (optional)
if [ "$p_hints" = yes ]; then echo "2/3 agent hints: already done"
elif [ ! -f "$HINTS" ]; then echo "2/3 agent hints: no local file at $HINTS, skipping (optional)"
else
  echo "2/3 This block would be appended to ~/.zshrc on $host:"; sed 's/^/    | /' "$HINTS"
  if ask "    Append it?"; then
    { cat <<'EOF'
set -e
rc="$HOME/.zshrc"; n=$(wc -l < "$rc"); before=$(sha256sum < "$rc" | cut -c1-16)
cp "$rc" "$rc.pre-agent-hints"
cat >> "$rc" <<'HINT'

# >>> agent-hints >>>
EOF
      cat "$HINTS"
      cat <<'EOF'
# <<< agent-hints <<<
HINT
after=$(head -n "$n" "$rc" | sha256sum | cut -c1-16)
[ "$before" = "$after" ] && echo "hint block added; the original lines are unchanged ($before)" \
  || echo "WARNING: original lines changed! backup: $rc.pre-agent-hints"
EOF
    } | rssh bash -s
  else echo "2/3 skipped"; fi
fi

# 3. herdr machine
if [ "$p_herdr" = yes ]; then echo "3/3 herdr machine: already saved"
elif ! command -v herdr >/dev/null 2>&1; then echo "3/3 herdr is not installed on this machine, skipping"
elif ask "3/3 Add $host to herdr as '$label' (herdr asks before installing on it)?"; then herdr machine add "$host" --label "$label"
else echo "3/3 skipped"; fi

probe && { echo "remote-setup: status after"; report
  if [ "$p_prompt" = yes ] && [ "$p_herdr" = yes ] && { [ "$p_hints" = yes ] || [ ! -f "$HINTS" ]; }; then
    echo "done. Open a new shell on $host to load it."; else echo "some steps are not done; run it again."; fi; }
