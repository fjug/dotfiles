# .zshenv — sourced for every zsh, including non-interactive ones.
# Keep this tiny and side-effect free; interactive setup belongs in .zshrc.

export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER=less
export LESS='-R -F -X'

# XDG base directories (used by starship, bat, gh, btop, ...)
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
