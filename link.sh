#!/usr/bin/env bash
# Symlink the tracked config files into $HOME. Safe to re-run at any time.

set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
source "$DOTFILES/install/lib.sh"

info "linking dotfiles from $DOTFILES"

link "$DOTFILES/.zshenv"          "$HOME/.zshenv"
link "$DOTFILES/.zshrc"           "$HOME/.zshrc"
link "$DOTFILES/.bashrc"          "$HOME/.bashrc"
link "$DOTFILES/.inputrc"         "$HOME/.inputrc"
link "$DOTFILES/.vimrc"           "$HOME/.vimrc"
link "$DOTFILES/.vim"             "$HOME/.vim"
link "$DOTFILES/.gitconfig"       "$HOME/.gitconfig"
link "$DOTFILES/.gitignore_global" "$HOME/.gitignore_global"

link "$DOTFILES/config/starship.toml" "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

# Remove symlinks left behind by the pre-2026 layout, whose targets are gone.
for stale in "$HOME/.bash_login" "$HOME/.oh-my-zsh" "$HOME/.hgrc"; do
  if [ -L "$stale" ] && [ ! -e "$stale" ]; then
    rm "$stale"
    warn "removed dangling symlink $stale"
  fi
done

# ~/.zshrc.local holds machine-specific, never-committed settings.
if [ ! -e "$HOME/.zshrc.local" ]; then
  cat > "$HOME/.zshrc.local" <<'EOF'
# Machine-local zsh settings. Not tracked by git.
# Licence paths, work-only hosts, anything that shouldn't be public.
EOF
  ok "created $HOME/.zshrc.local"
fi

info "done"
