# --- completion --------------------------------------------------------------

typeset -U fpath

# Homebrew-provided completions (git, gh, docker, ...)
if command -v brew >/dev/null 2>&1; then
  _brew_prefix="$(brew --prefix)"
  fpath=("$_brew_prefix/share/zsh/site-functions" "$_brew_prefix/share/zsh-completions" $fpath)
  unset _brew_prefix
fi
[ -d "$DOTFILES/zsh/completions" ] && fpath=("$DOTFILES/zsh/completions" $fpath)

# Completions for uv, uvx and gh, generated once into an fpath directory so
# compinit picks them up lazily on first <Tab>. Previously these were three
# `eval "$(... completion zsh)"` calls — three forks plus three tool start-ups
# on every single shell. The bash side does the same via bash-completion's
# user directory.
_zcompl="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/completions"
fpath=("$_zcompl" $fpath)

# _gen_completion <binary> <_outfile> <command...>
_gen_completion() {
  local bin=$1 out="$_zcompl/$2" exe
  shift 2
  exe=$(command -v "$bin") || return 0
  [[ -s $out && ! $exe -nt $out ]] && return 0
  mkdir -p "$_zcompl" || return 1
  if "$@" > "$out.$$" 2>/dev/null && [[ -s $out.$$ ]]; then
    command mv -f "$out.$$" "$out"
    _zcompl_changed=1
  else
    command rm -f "$out.$$"
  fi
}

_zcompl_changed=
_gen_completion uv  _uv  uv generate-shell-completion zsh
_gen_completion uvx _uvx uvx --generate-shell-completion zsh
_gen_completion gh  _gh  gh completion -s zsh

autoload -Uz compinit

# Rebuild the completion cache at most once a day; otherwise load it as-is.
# This is the single biggest zsh startup win.
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${_zcompdump:h}"
# A freshly generated completion is invisible to `compinit -C`, which reuses
# the dump as-is. Drop the dump so the next compinit is a full one.
[[ -n $_zcompl_changed ]] && command rm -f "$_zcompdump" "$_zcompdump.zwc"
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump _zcompl_changed
unfunction _gen_completion

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Never offer the current directory back on cd ..
zstyle ':completion:*:cd:*' ignore-parents parent pwd
