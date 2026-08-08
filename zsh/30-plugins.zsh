# --- zsh plugins -------------------------------------------------------------
#
# No plugin manager. Plugins are plain git clones under
# $XDG_DATA_HOME/zsh/plugins, fetched on first run. That keeps this identical
# on macOS and Linux, with nothing to update but git itself.

ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# zplug <user/repo> [file-to-source]
zplug() {
  local repo="$1" name="${1##*/}" file="$2" dir
  dir="$ZSH_PLUGIN_DIR/$name"
  if [[ ! -d "$dir" ]]; then
    print -P "%F{yellow}installing zsh plugin $repo...%f"
    command git clone --depth=1 -q "https://github.com/$repo.git" "$dir" || return 1
  fi
  source "$dir/${file:-$name.zsh}"
}

zplug zsh-users/zsh-autosuggestions
zplug zsh-users/zsh-completions            zsh-completions.plugin.zsh
zplug zsh-users/zsh-history-substring-search
# Syntax highlighting must be sourced after everything that defines widgets.
zplug zsh-users/zsh-syntax-highlighting

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# `dotfiles-update-plugins` pulls every plugin.
dotfiles-update-plugins() {
  local d
  for d in "$ZSH_PLUGIN_DIR"/*(N/); do
    print -P "%F{blue}${d:t}%f"
    command git -C "$d" pull --quiet --ff-only
  done
}
