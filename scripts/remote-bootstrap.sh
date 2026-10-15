#!/usr/bin/env bash
# Personal-dotfiles bootstrap for a remote workspace. Run by hand (it is not installed as a start hook), and safe to
# re-run: it is idempotent. The source of truth is this public repo; nothing is hosted on the workspace's employer.
#
# Deliberately thin. It does three things, all as the current user, no sudo:
#   1. installs two pinned, checksum-verified tools into ~/.local/bin (chezmoi, starship)
#   2. applies ONLY the prompt from a public personal repo (allow-list lives in that repo's .chezmoiignore)
#   3. appends one marker-delimited loader block to ~/.zshrc
# Every step fails soft and the script always exits 0, so it can never break a shell or a workspace.
#
# Opt out any time:  touch ~/.no-personal-dotfiles      (and delete the marked block in ~/.zshrc)
# Run by hand:       curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/<commit>/scripts/remote-bootstrap.sh | bash

PERSONAL_REPO="${PERSONAL_REPO:-https://github.com/nio-not-neo/dotfiles.git}"   # env override is for testing

# The ONLY files this bridge will ever apply to this workspace. This list is enforced here, independent of the
# personal repo's own .chezmoiignore: if the repo would apply anything else, nothing is applied.
ALLOWED_FILES=".config/starship.toml
.config/zsh/85-pokeball.zsh
.config/zsh/90-prompt.zsh"

# Pinned releases. Hashes are of the release tarballs and match the checksums the projects publish.
CHEZMOI_VERSION="2.73.0"
CHEZMOI_SHA256="b597729b687af4488a848240134cb633de8ca0f04e0d26d48f400ee2ac338ffa"
STARSHIP_VERSION="1.26.0"
STARSHIP_SHA256="321f0dd7af8340a5f2e6a8fec6538a04f617486f9ec70d878f91c09cd8deef22"

BIN="$HOME/.local/bin"
MARK_BEGIN="# >>> personal-dotfiles >>>"
MARK_END="# <<< personal-dotfiles <<<"

log() { echo "[personal-dotfiles] $*"; }

# install_tool <name> <version> <sha256> <url>
# Skips when the pinned version is already installed; otherwise downloads, verifies, extracts only the binary.
install_tool() {
  local name="$1" version="$2" sha="$3" url="$4" tmp
  if "$BIN/$name" --version 2>/dev/null | grep -q "$version"; then
    return 0
  fi
  tmp="$(mktemp -d)" || { log "$name: no temp dir, skipping"; return 1; }
  if ! curl -fsSL --max-time 60 --retry 2 -o "$tmp/$name.tgz" "$url"; then
    log "$name: download failed, skipping"; rm -rf "$tmp"; return 1
  fi
  if [ "$(sha256sum "$tmp/$name.tgz" | cut -d' ' -f1)" != "$sha" ]; then
    log "$name: checksum mismatch, refusing to install"; rm -rf "$tmp"; return 1
  fi
  if ! tar -xzf "$tmp/$name.tgz" -C "$tmp" "$name" 2>/dev/null; then
    log "$name: binary not found in archive, skipping"; rm -rf "$tmp"; return 1
  fi
  install -m 755 "$tmp/$name" "$BIN/$name" && log "$name $version installed"
  rm -rf "$tmp"
}

# First run only: select the restricted profile. Never overwrites an existing, possibly hand-edited, config.
configure_profile() {
  local cfg="$HOME/.config/chezmoi/chezmoi.toml"
  [ -e "$cfg" ] && return 0
  mkdir -p "$(dirname "$cfg")" && printf '[data]\nprofile = "remote"\n' > "$cfg"
}

# Clone/update the personal repo and apply the allow-listed files.
# Git is isolated from this host's global config so no work identity or credential helper is involved.
apply_dotfiles() {
  [ -x "$BIN/chezmoi" ] || { log "chezmoi missing, skipping apply"; return 1; }
  export GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0

  # Fetch only (no apply yet).
  if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
    timeout 60 "$BIN/chezmoi" git -- pull --quiet --ff-only 2>&1 \
      || log "pull failed or timed out, checking the config already on disk"
  else
    timeout 90 "$BIN/chezmoi" init --depth 1 "$PERSONAL_REPO" 2>&1 \
      || { log "first fetch failed or timed out, will retry on next start"; return 1; }
  fi

  # Guard: refuse to apply anything outside ALLOWED_FILES, whatever the repo's own ignore rules say.
  local managed extra
  managed="$("$BIN/chezmoi" managed --include=files 2>/dev/null | sort)"
  [ -n "$managed" ] || { log "nothing to apply"; return 0; }
  extra="$(comm -23 <(printf '%s\n' "$managed") <(printf '%s\n' "$ALLOWED_FILES" | sort))"
  if [ -n "$extra" ]; then
    log "REFUSING to apply: the repo would also manage files outside the allow-list:"
    printf '%s\n' "$extra" | sed 's/^/[personal-dotfiles]   /'
    return 1
  fi

  timeout 60 "$BIN/chezmoi" apply 2>&1 || log "apply failed or timed out, keeping the existing config"
}

# Add the loader to ~/.zshrc once, between markers. Exports PATH itself because ~/.local/bin is not on PATH
# in non-login shells here. Appending (not tracking .zshrc) keeps the host's file under the host's control.
ensure_loader() {
  local rc="$HOME/.zshrc"
  [ -f "$rc" ] || { log "no ~/.zshrc, skipping loader"; return 0; }
  [ -f "$HOME/.config/zsh/90-prompt.zsh" ] || { log "prompt not applied, skipping loader"; return 0; }
  grep -qF "$MARK_BEGIN" "$rc" && return 0
  {
    echo
    echo "$MARK_BEGIN (added by remote-bootstrap.sh; delete this block to disable)"
    echo '[[ -d ~/.local/bin && ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"'
    echo 'for f in ~/.config/zsh/*.zsh(N); do source "$f"; done; unset f'
    echo "$MARK_END"
  } >> "$rc" && log "loader added to ~/.zshrc"
}

main() {
  [ -e "$HOME/.no-personal-dotfiles" ] && { log "disabled by ~/.no-personal-dotfiles"; return 0; }
  [ "$(uname -s)-$(uname -m)" = "Linux-x86_64" ] || { log "unsupported platform, skipping"; return 0; }
  mkdir -p "$BIN" || return 0

  install_tool chezmoi "$CHEZMOI_VERSION" "$CHEZMOI_SHA256" \
    "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz"
  install_tool starship "$STARSHIP_VERSION" "$STARSHIP_SHA256" \
    "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz"

  configure_profile
  apply_dotfiles
  ensure_loader
}

main
exit 0
