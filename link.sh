#!/usr/bin/env bash
# Symlink the tracked config files into $HOME. Safe to re-run at any time.
# Works on macOS and Linux; platform-specific links are guarded.

set -uo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "$DOTFILES/install/lib.sh"
set +e

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

info "linking dotfiles from $DOTFILES"

# --- shells ------------------------------------------------------------------
link "$DOTFILES/.zshenv"           "$HOME/.zshenv"
link "$DOTFILES/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/.bashrc"           "$HOME/.bashrc"
link "$DOTFILES/.bash_profile"     "$HOME/.bash_profile"
link "$DOTFILES/.inputrc"          "$HOME/.inputrc"

# --- git ---------------------------------------------------------------------
link "$DOTFILES/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/.gitignore_global" "$HOME/.gitignore_global"

# --- vim ---------------------------------------------------------------------
link "$DOTFILES/.vimrc"            "$HOME/.vimrc"
link "$DOTFILES/.vim"              "$HOME/.vim"

# --- XDG config --------------------------------------------------------------
link "$DOTFILES/config/starship.toml" "$CFG/starship.toml"
link "$DOTFILES/config/bat/config"    "$CFG/bat/config"

# --- macOS only --------------------------------------------------------------
# Sane Home/End/PageUp/PageDown in every Cocoa text field.
if is_macos; then
  link "$DOTFILES/KeyBindings/DefaultKeyBinding.dict" \
       "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
fi

# --- stale symlinks from older layouts ---------------------------------------
for stale in "$HOME/.bash_login" "$HOME/.oh-my-zsh" "$HOME/.hgrc" "$HOME/.bash_local"; do
  if [ -L "$stale" ] && [ ! -e "$stale" ]; then
    rm "$stale"
    warn "removed dangling symlink $stale"
  fi
done

# --- machine-local files, never tracked --------------------------------------
for pair in \
  "$HOME/.zshrc.local:zsh" \
  "$HOME/.bashrc.local:bash"
do
  f="${pair%%:*}"; which_sh="${pair##*:}"
  if [ ! -e "$f" ]; then
    cat > "$f" <<LOCAL
# Machine-local $which_sh settings. Not tracked by git.
# Licence paths, work-only hosts, anything that shouldn't be public.
LOCAL
    ok "created $f"
  fi
done

# git-lfs: the filter is deliberately absent from the tracked .gitconfig,
# because `required = true` breaks checkouts on a machine without git-lfs.
# Add it here instead, only where git-lfs actually exists.
if has git-lfs && ! grep -q '\[filter "lfs"\]' "$HOME/.gitconfig.local" 2>/dev/null; then
  cat >> "$HOME/.gitconfig.local" <<'LFS'
[filter "lfs"]
	required = true
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
LFS
  ok "enabled git-lfs filter in ~/.gitconfig.local"
fi

info "done"
