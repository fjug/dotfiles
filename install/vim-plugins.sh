#!/usr/bin/env bash
# Vim plugins. .vimrc loads them with pathogen, which auto-sources anything
# under .vim/bundle/, so these are plain git clones with nothing to register.
#
# The old setup.sh cloned these and was deleted in the 2026 cleanup, after
# which nothing did — .gitignore reserved the slots but they stayed empty.
# Vundle is deliberately not among them: it is a plugin manager, and pathogen
# already is one.
#
# Idempotent: existing clones are pulled, not re-cloned.

set -uo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES/install/lib.sh"
set +e

BUNDLE="$DOTFILES/.vim/bundle"
mkdir -p "$BUNDLE"

PLUGINS="
preservim/nerdcommenter
vim-airline/vim-airline
tpope/vim-sensible
"

rc=0
for repo in $PLUGINS; do
  name="${repo##*/}"
  if [ -d "$BUNDLE/$name/.git" ]; then
    git -C "$BUNDLE/$name" pull --quiet --ff-only && ok "$name (updated)" \
      || { warn "$name: pull failed"; rc=1; }
  else
    git clone --depth=1 --quiet "https://github.com/$repo.git" "$BUNDLE/$name" \
      && ok "$name (cloned)" || { warn "$name: clone failed"; rc=1; }
  fi
done

exit $rc
