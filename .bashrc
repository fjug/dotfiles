# .bashrc — interactive bash configuration.
#
# A thin loader: everything real lives in $DOTFILES/bash/*.bash and is sourced
# in numeric order, mirroring how .zshrc loads $DOTFILES/zsh/*.zsh. To add
# something, drop a file in there rather than growing this one.
#
# zsh remains the login shell on the Macs; this is what you get on the Linux
# boxes, and whenever you run bash here.
#
# Machine-specific settings that must not be committed go in ~/.bashrc.local.

# --- things non-interactive shells need too ----------------------------------
# $HOME/.local/bin must be on PATH for non-interactive shells as well (the
# VS Code server, scp, remote git hooks), so it is set before the bail-out.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# if not running interactively, stop here
case $- in *i*) ;; *) return ;; esac

# --- where this repo lives ---------------------------------------------------
# Derived from where this file really is, so it works via the ~/.bashrc
# symlink and from a clone in any location. Deliberately not taken from the
# environment: a zsh started elsewhere may export a different DOTFILES.
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  _src="${BASH_SOURCE[0]}"
  if [ -L "$_src" ]; then
    _src="$(readlink "$_src")"
    case "$_src" in /*) ;; *) _src="$HOME/$_src" ;; esac
  fi
  DOTFILES="$(cd "$(dirname "$_src")" && pwd)"
  unset _src
fi
export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

for _bfile in "$DOTFILES"/bash/*.bash; do
  [ -r "$_bfile" ] && . "$_bfile"
done
unset _bfile

# --- machine-local overrides, not tracked by git -----------------------------
[ -r "$HOME/.bash_local" ]   && . "$HOME/.bash_local"     # older name
[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
