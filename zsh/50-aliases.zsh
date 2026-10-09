# --- aliases -----------------------------------------------------------------
# The bulk lives in shell/aliases.sh, shared with bash so the two shells can't
# drift apart. Only zsh-specific aliases belong below.

source "$DOTFILES/shell/aliases.sh"

alias zshconfig='$EDITOR $DOTFILES/.zshrc'

# `pip!` works in zsh; bash gets `realpip` instead, because a trailing `!`
# collides with history expansion there. Both are defined in zsh.
alias 'pip!'='command pip'
