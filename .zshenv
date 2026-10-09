# .zshenv — sourced for every zsh, including non-interactive ones.
# Keep this tiny: the actual environment is shared with bash in shell/env.sh.

export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
[ -r "$DOTFILES/shell/env.sh" ] && . "$DOTFILES/shell/env.sh"
