#!/usr/bin/env bash
# link-configs.sh — symlink the tool configs ported from the Mac (~/.dotfiles)
# into $HOME / ~/.config. Safe to re-run. Anything already there that is not
# the right symlink is moved aside to <name>.bak.<timestamp>.
#
# (The older config-links.sh handles bashrc/gitconfig/vimrc & co.; it is
# left alone because ~/.bashrc is now a direct symlink rather than a stub.)

set -euo pipefail
DOTFILES="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP=$(date +%Y%m%dT%H%M%S)

link() {
	local src="$1" dest="$2"
	mkdir -p "$(dirname "$dest")"
	if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
		echo "ok      $dest"
		return
	fi
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		mv "$dest" "$dest.bak.$STAMP"
		echo "backup  $dest -> $dest.bak.$STAMP"
	fi
	ln -s "$src" "$dest"
	echo "linked  $dest -> $src"
}

link "$DOTFILES/bashrc"               "$HOME/.bashrc"
link "$DOTFILES/gitconfig"            "$HOME/.gitconfig"
link "$DOTFILES/gitignore_global"     "$HOME/.gitignore_global"
link "$DOTFILES/inputrc"              "$HOME/.inputrc"
link "$DOTFILES/config/starship.toml" "$CFG/starship.toml"
link "$DOTFILES/config/bat/config"    "$CFG/bat/config"
