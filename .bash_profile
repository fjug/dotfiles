# .bash_profile — login shells.
#
# macOS runs every Terminal window as a login shell, and a login bash reads
# this file and NOT ~/.bashrc. Without this file the whole bash setup would
# silently never load here.

[ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"
