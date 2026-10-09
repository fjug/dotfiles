# --- helpers -----------------------------------------------------------------
# Loaded early; later modules depend on these.

# _cached_init <name> "<dep files>" <cmd> [args...]
#
# Source the shell code <cmd> prints, cached under $XDG_CACHE_HOME/zsh-init/.
# Each `eval "$(tool init zsh)"` is a fork plus the tool's own startup; this
# pays that once instead of on every shell. The cache is rebuilt when it is
# missing or any dependency file (the binary, its config) is newer.
#
# The bash side has the same function in bash/00-lib.bash, keyed by bash
# version. zsh needs no such key: there is only one zsh here.
_cached_init() {
  local name=$1 deps=$2 f d stale=
  f="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init/$name.zsh"
  shift 2
  [[ -s $f ]] || stale=1
  for d in ${=deps}; do
    [[ -n $d && $d -nt $f ]] && stale=1
  done
  if [[ -n $stale ]]; then
    mkdir -p ${f:h} || return 1
    if ! "$@" > $f.$$ 2>/dev/null; then
      command rm -f $f.$$
      return 1
    fi
    command mv -f $f.$$ $f
  fi
  source $f
}

# dotfiles-clear-cache — drop the generated init code and completions, so the
# next shell regenerates everything. Use after upgrading the tools by hand.
dotfiles-clear-cache() {
  command rm -rf \
    "${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/bash-init" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
  print "cleared; open a new shell to regenerate"
}

# starship's zsh init, made cheaper (only used through _cached_init).
#
# Unlike bash, nothing needs doing about `starship time`: starship's own zsh
# init already uses zmodload zsh/datetime and $EPOCHREALTIME on zsh 5+. What
# is left is PROMPT2, which is computed by a subshell at source time — so it
# would still spawn on every shell even from the cache. Precompute it.
#
# If a future starship prints different init code the substitution simply does
# not match, and the cache keeps the original line.
_starship_init_zsh() {
  local exe init
  exe=$(command -v starship) || return 1
  init=$("$exe" init zsh) || return 1
  init=${init//$'\n'"PROMPT2=\"\$($exe prompt --continuation)\""/}
  print -r -- "$init"
  printf 'PROMPT2=%q\n' "$(STARSHIP_SHELL=zsh "$exe" prompt --continuation)"
}
