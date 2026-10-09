# --- external tool integration ----------------------------------------------
# Every block is guarded, so this file is a no-op on a bare HPC login node
# where you cannot install anything.

# zoxide: `z <fragment>` jumps to a frecent directory.
_bin zoxide && _cached_init zoxide "$REPLY" zoxide init bash

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd.
if command -v fzf > /dev/null 2>&1; then
  # `fzf --bash` exists in fzf 0.48+; older distro packages ship key-bindings
  # as files instead.
  if ! { _bin fzf && _cached_init fzf "$REPLY" fzf --bash; } \
     || ! command -v __fzf_history__ > /dev/null 2>&1; then
    for _fz in "${BREW:-/nonexistent}/opt/fzf/shell/key-bindings.bash" \
               /usr/share/fzf/shell/key-bindings.bash \
               /usr/share/doc/fzf/examples/key-bindings.bash; do
      [ -r "$_fz" ] && . "$_fz" && break
    done
    unset _fz
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  if command -v fd > /dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  command -v bat > /dev/null 2>&1 && \
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {} 2>/dev/null | head -200'"
fi

# bat: man pages through bat. The theme lives in config/bat/config, so bat
# also looks right outside an interactive shell (scripts, fzf previews).
command -v bat > /dev/null 2>&1 && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# uv: let uv manage interpreters. On a machine that still has conda, an
# activated conda env still takes priority for `uv pip`.
command -v uv > /dev/null 2>&1 && export UV_PYTHON_PREFERENCE=managed

# ssh-agent.
# macOS: the login keychain holds the passphrases (see ssh/config.example).
# Linux: share one systemd user agent across all shells, unless an agent is
# already provided (e.g. forwarded over ssh).
if [ -n "${IS_MACOSX:-}" ]; then
  ssh-add -l > /dev/null 2>&1 || ssh-add --apple-load-keychain > /dev/null 2>&1
elif [ -z "${SSH_AUTH_SOCK:-}" ] && [ -n "${XDG_RUNTIME_DIR:-}" ] \
     && command -v systemctl > /dev/null 2>&1; then
  [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ] \
    || systemctl --user start ssh-agent.service > /dev/null 2>&1
  [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ] && \
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
