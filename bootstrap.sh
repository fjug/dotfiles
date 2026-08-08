#!/usr/bin/env bash
# Set up a fresh machine from this repo.
#
#   git clone git@github.com:fjug/.dotfiles.git ~/.dotfiles
#   ~/.dotfiles/bootstrap.sh
#
# Idempotent — safe to run again on a machine that's already set up.
#
# Environment switches:
#   DOTFILES_YES=1    don't ask anything, assume yes
#   DOTFILES_APPS=1   also install the GUI apps from Brewfile.apps (macOS)

set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export DOTFILES
source "$DOTFILES/install/lib.sh"

cat <<BANNER

  dotfiles bootstrap
  ------------------
  repo:     $DOTFILES
  platform: $OS
  python:   uv only (no conda)

BANNER

confirm "Continue?" || exit 0

# 1. packages ------------------------------------------------------------------
info "step 1/4 — packages"
bash "$DOTFILES/install/packages.sh"

# 2. symlinks ------------------------------------------------------------------
info "step 2/4 — symlinks"
bash "$DOTFILES/link.sh"

# 3. python --------------------------------------------------------------------
info "step 3/4 — python toolchain"
bash "$DOTFILES/install/python-uv.sh"

# 4. shell ---------------------------------------------------------------------
info "step 4/4 — shell"
if [ "$(basename "${SHELL:-}")" != zsh ]; then
  zsh_path="$(command -v zsh)"
  if confirm "Make zsh ($zsh_path) the login shell?"; then
    grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$zsh_path"
  fi
fi

# The zsh plugins clone themselves on first interactive start; do it now so the
# first real shell doesn't stall.
info "pre-fetching zsh plugins"
zsh -i -c 'exit' >/dev/null 2>&1 || warn "first zsh start reported an issue — run 'zsh -i' to see it"

cat <<NEXT

  ${_c_green}done${_c_off}

  Still to do by hand:
    - open a new terminal (or: exec zsh)
    - ssh keys: copy ~/.ssh/id_ed25519 + ~/.ssh/ht across, then
        cp $DOTFILES/ssh/config.example ~/.ssh/config   # and edit
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    - gh auth login
    - GUI apps:  brew bundle --file=$DOTFILES/Brewfile.apps
    - macOS prefs: $DOTFILES/install/macos-defaults.sh
    - see docs/NEW-MACHINE.md for the full checklist

NEXT
