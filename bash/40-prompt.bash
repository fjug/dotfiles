# --- prompt ------------------------------------------------------------------

if command -v starship > /dev/null 2>&1; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
  # No "scan timed out" warnings in the prompt on a CPU-throttled VDI or an
  # NFS home directory.
  export STARSHIP_LOG=error
  _bin starship && _cached_init starship "$REPLY $STARSHIP_CONFIG" _starship_init
else
  # No starship: a git-aware prompt with no external dependencies, matching
  # the shape of the zsh fallback in zsh/40-tools.zsh.
  _SHELL_PROMPT=': ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w'
  if [ "$(__git_ps1 x 2> /dev/null)" = "x" ]; then
    PS1="$_SHELL_PROMPT"'\[\033[01;33m\]$(__git_ps1 " (%s)")\[\033[00m\]\n\$ '
  else
    __branch() { git branch --show-current 2> /dev/null | sed 's/.*/ (&)/'; }
    PS1="$_SHELL_PROMPT"'\[\033[01;33m\]$(__branch)\[\033[00m\]\n\$ '
  fi
fi

# Identify the chroot you are in, used by the fallback prompt above.
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi
