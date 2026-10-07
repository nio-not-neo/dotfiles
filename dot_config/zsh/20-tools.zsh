# Version managers. Each is guarded so a machine without the tool still starts cleanly.

# nvm, lazy-loaded. Sourcing nvm.sh and running `nvm use` cost ~1s per shell, so the default
# node's bin goes straight on PATH and nvm itself only loads the first time you call `nvm`.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _nvm_load() {
    unset -f nvm _nvm_load
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  }
  _nvm_default="$(<"$NVM_DIR/alias/default" 2>/dev/null)"
  _nvm_dirs=("$NVM_DIR"/versions/node/v${_nvm_default#v}*(N/))
  if [[ -n $_nvm_default && ${#_nvm_dirs} -gt 0 ]]; then
    export PATH="${_nvm_dirs[-1]}/bin:$PATH"
    nvm() { _nvm_load; nvm "$@"; }
  else
    _nvm_load   # default alias isn't a plain version (e.g. lts/*): load eagerly
  fi
  unset _nvm_default _nvm_dirs
fi

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
