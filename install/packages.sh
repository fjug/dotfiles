#!/usr/bin/env bash
# Install Homebrew (macOS / Linuxbrew) and everything in the Brewfile.
# On Linux without brew, falls back to the native package manager.

set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES/install/lib.sh"

# --- Homebrew ----------------------------------------------------------------
if ! has brew; then
  if is_macos; then
    info "installing Homebrew"
    # Xcode command line tools first — brew needs them.
    xcode-select -p >/dev/null 2>&1 || xcode-select --install || true
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    warn "Homebrew not found; using the system package manager instead"
  fi
fi

# Make brew visible in this script's shell regardless of where it landed.
load_brew || true

# --- macOS / Linuxbrew path --------------------------------------------------
if has brew; then
  info "updating Homebrew"
  brew update

  info "installing from Brewfile"
  brew bundle --file="$DOTFILES/Brewfile"

  if is_macos && [ "${DOTFILES_APPS:-0}" = 1 ]; then
    info "installing GUI apps from Brewfile.apps"
    brew bundle --file="$DOTFILES/Brewfile.apps"
  elif is_macos; then
    info "skipping GUI apps — review Brewfile.apps, then:"
    printf '      brew bundle --file=%s/Brewfile.apps\n' "$DOTFILES"
  fi

  info "upgrading anything already installed but outdated"
  brew upgrade

  brew cleanup

  # `$(brew --prefix)/share` ships group-writable, which makes compinit flag
  # every Homebrew completion directory as insecure and prompt on the first
  # interactive shell. Homebrew's own documented fix.
  if [ -d "$(brew --prefix)/share" ]; then
    chmod go-w "$(brew --prefix)/share" 2>/dev/null || true
  fi

  ok "Homebrew done"
  exit 0
fi

# --- plain Linux fallback ----------------------------------------------------
mgr="$(linux_pkg_mgr)" || die "no supported package manager found"
info "installing packages with $mgr"

pkgs="zsh git git-lfs curl wget vim ripgrep fd-find bat fzf jq tree btop"

case "$mgr" in
  apt-get)
    sudo apt-get update
    # shellcheck disable=SC2086
    sudo apt-get install -y $pkgs eza zoxide git-delta || {
      warn "some packages are unavailable on this release; installing the core set"
      # shellcheck disable=SC2086
      sudo apt-get install -y $pkgs
    }
    # Debian/Ubuntu name these differently; add the familiar names back.
    mkdir -p "$HOME/.local/bin"
    [ -x /usr/bin/batcat ] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
    [ -x /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
    ;;
  dnf)    sudo dnf install -y $pkgs eza zoxide git-delta || sudo dnf install -y $pkgs ;;
  pacman) sudo pacman -Sy --needed --noconfirm $pkgs eza zoxide git-delta starship ;;
  zypper) sudo zypper install -y $pkgs ;;
esac

# starship and lazygit are rarely packaged; use their own installers.
has starship || curl -sS https://starship.rs/install.sh | sh -s -- --yes
ok "packages done"
