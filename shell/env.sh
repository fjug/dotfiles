# Environment shared by zsh and bash, on macOS and Linux.
#
# Sourced from .zshenv (so it applies to non-interactive zsh too) and from
# bash/10-path.bash. Must be side-effect free: variables only, no commands
# that assume an interactive terminal.
#
# Valid in zsh, bash 5.x and bash 3.2 alike.

export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# --- platform ----------------------------------------------------------------
# From $OSTYPE rather than $(uname), which would cost a fork on every shell.
case "$OSTYPE" in
  darwin*)       OS_NAME=Darwin; IS_MACOSX=1 ;;
  linux*)        OS_NAME=Linux;  IS_LINUX=1  ;;
  cygwin*|msys*) OS_NAME=CYGWIN; IS_WINDOWS=1 ;;
  *)             OS_NAME="$(uname)" ;;
esac
export OS_NAME
[ -n "${IS_MACOSX:-}" ]  && export IS_MACOSX
[ -n "${IS_LINUX:-}" ]   && export IS_LINUX
[ -n "${IS_WINDOWS:-}" ] && export IS_WINDOWS

# --- editor and pager --------------------------------------------------------
export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER=less
# raw colours, quit if it fits on one screen, don't clear the screen on exit
export LESS='-R -F -X'

# --- XDG base directories ----------------------------------------------------
# Used by starship, bat, gh, btop, and the bash init cache.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# --- colours -----------------------------------------------------------------
# CLICOLOR/LSCOLORS drive BSD ls (macOS); LS_COLORS drives GNU ls and eza.
export CLICOLOR=1
export LSCOLORS=dxfxcxdxbxegedabagacad
export LS_COLORS='di=33:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# --- locale ------------------------------------------------------------------
# Only if the terminal or ssh client did not provide one. A missing LANG means
# bash warns about setlocale and UTF-8 glyphs (the starship prompt, em-dashes)
# render as mojibake. en_US.UTF-8 always exists on macOS; C.UTF-8 is the safe
# choice on Linux, where en_US may not have been generated.
if [ -z "${LANG:-}" ] && [ -z "${LC_ALL:-}" ]; then
  if [ -n "${IS_MACOSX:-}" ]; then
    export LANG=en_US.UTF-8
  else
    export LANG=C.UTF-8
  fi
fi

# --- misc --------------------------------------------------------------------
# indent XML with tabs
XMLLINT_INDENT='	'
export XMLLINT_INDENT
