# --- functions ---------------------------------------------------------------
# Shared with zsh in shell/functions.sh.

[ -r "$DOTFILES/shell/functions.sh" ] && . "$DOTFILES/shell/functions.sh"

# tt <title> — set the terminal title.
tt() { TERM_TITLE="$*"; printf '\033]0;%s\007' "$*"; }
