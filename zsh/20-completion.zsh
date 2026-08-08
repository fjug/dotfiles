# --- completion --------------------------------------------------------------

typeset -U fpath

# Homebrew-provided completions (git, gh, docker, ...)
if command -v brew >/dev/null 2>&1; then
  _brew_prefix="$(brew --prefix)"
  fpath=("$_brew_prefix/share/zsh/site-functions" "$_brew_prefix/share/zsh-completions" $fpath)
  unset _brew_prefix
fi
[ -d "$DOTFILES/zsh/completions" ] && fpath=("$DOTFILES/zsh/completions" $fpath)

autoload -Uz compinit

# Rebuild the completion cache at most once a day; otherwise load it as-is.
# This is the single biggest zsh startup win.
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${_zcompdump:h}"
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Never offer the current directory back on cd ..
zstyle ':completion:*:cd:*' ignore-parents parent pwd
