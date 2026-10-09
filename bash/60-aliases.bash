# --- aliases -----------------------------------------------------------------
# The bulk is shared with zsh in shell/aliases.sh; only bash-specific aliases
# belong below.

[ -r "$DOTFILES/shell/aliases.sh" ] && . "$DOTFILES/shell/aliases.sh"

alias bashconfig='$EDITOR "$DOTFILES/.bashrc"'
