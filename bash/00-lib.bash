# --- helpers -----------------------------------------------------------------
# Loaded first; the later modules depend on these. Written for speed: on a
# CPU-throttled VDI every fork can cost ~0.1 s, so these avoid subshells.

# _bin <cmd>: set REPLY to the full path of <cmd> on PATH, without forking.
_bin() {
  REPLY=
  hash "$1" 2> /dev/null && REPLY="${BASH_CMDS[$1]}"
  [ -n "$REPLY" ]
}

# _path_prepend <dir>: put <dir> at the front of PATH, moving it there if it
# is already present, and doing nothing if it does not exist.
_path_prepend() {
  [ -d "$1" ] || return 0
  PATH=":$PATH:"
  PATH="${PATH//:$1:/:}"
  PATH="${PATH#:}"; PATH="${PATH%:}"
  export PATH="$1${PATH:+:$PATH}"
}

# _cached_init <name> "<dep files>" <cmd> [args...]
# Source the shell code <cmd> prints, cached in $XDG_CACHE_HOME/bash-init/.
# Running starship, zoxide and fzf init on every shell costs ~100 ms; this
# pays it once. The cache is rebuilt when it is missing or any dep file is
# newer. install/linux-tools.sh clears it after installing a new version.
_cached_init() {
  local name="$1" deps="$2" f="${XDG_CACHE_HOME:-$HOME/.cache}/bash-init/$1.bash" d stale=
  shift 2
  [ -s "$f" ] || stale=1
  for d in $deps; do [ "$d" -nt "$f" ] && stale=1; done
  if [ -n "$stale" ]; then
    mkdir -p "${f%/*}" || return 1
    if ! "$@" > "$f.$$" 2> /dev/null; then
      command rm -f "$f.$$"
      return 1
    fi
    mv -f "$f.$$" "$f"
  fi
  . "$f"
}

# starship's bash init, made cheaper (only ever used through _cached_init):
# `starship time` — one spawn at startup plus two per command — becomes bash's
# own $EPOCHREALTIME in ms, and the continuation prompt PS2 is computed once
# instead of on every startup. If a future starship prints different init
# code the substitutions simply do not match, and nothing changes.
_starship_init() {
  local exe init
  exe="$(command -v starship)" || return 1
  init="$("$exe" init bash --print-full-init)" || return 1
  init="${init//"\$($exe time)"/'$(( ${EPOCHREALTIME//[!0-9]/} / 1000 ))'}"
  init="${init//"$exe time"/'echo $(( ${EPOCHREALTIME//[!0-9]/} / 1000 ))'}"
  init="${init//$'\n'"PS2=\"\$($exe prompt --continuation)\""/}"
  printf '%s\n' "$init"
  printf 'PS2=%q\n' "$(STARSHIP_SHELL=bash "$exe" prompt --continuation)"
}
