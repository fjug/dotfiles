#!/usr/bin/env bash
# Install Homebrew (macOS / Linuxbrew) and everything in the Brewfile.
# On Linux without brew, falls back to the native package manager.
#
# One failing formula or cask must not take the rest down with it: if
# `brew bundle` reports a problem, every entry is retried individually so you
# end up with as much installed as possible, and a list of what didn't work.

set -uo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES/install/lib.sh"
set +e

# --- Xcode Command Line Tools ------------------------------------------------
# Homebrew needs these. `xcode-select --install` opens a GUI installer and
# returns immediately, so we have to wait for it — otherwise brew starts
# against a half-installed toolchain and fails in confusing ways.
if is_macos && ! xcode-select -p >/dev/null 2>&1; then
  info "installing Xcode Command Line Tools — accept the dialog that just opened"
  xcode-select --install >/dev/null 2>&1
  printf '     waiting'
  while ! xcode-select -p >/dev/null 2>&1; do
    printf '.'
    sleep 10
  done
  echo
  ok "Command Line Tools installed"
fi

# --- Homebrew ----------------------------------------------------------------
if ! load_brew; then
  if is_macos; then
    info "installing Homebrew (this asks for your password)"
    /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || die "Homebrew installation failed — fix that first, then re-run this script"
    load_brew || die "Homebrew installed but not found on PATH"
  else
    warn "Homebrew not found; using the system package manager instead"
  fi
fi

# --- macOS / Linuxbrew path --------------------------------------------------
if has brew; then
  info "updating Homebrew"
  brew update

  # Retry the Brewfile entry by entry, so one bad item costs you one item.
  bundle_with_fallback() {
    local file="$1" label="$2" line kind name
    info "installing from $(basename "$file")"
    if brew bundle --file="$file"; then
      ok "$label complete"
      return 0
    fi

    warn "$label had failures — retrying each entry individually"
    local failed=()
    while read -r line; do
      case "$line" in
        brew\ *|cask\ *) ;;
        *) continue ;;
      esac
      kind="${line%% *}"
      name="$(printf '%s' "$line" | sed -E 's/^[a-z]+ +"([^"]+)".*/\1/')"
      [ -n "$name" ] || continue
      if [ "$kind" = cask ]; then
        brew list --cask "$name" >/dev/null 2>&1 && continue
        brew install --cask "$name" >/dev/null 2>&1 || failed+=("cask $name")
      else
        brew list --formula "$name" >/dev/null 2>&1 && continue
        brew install "$name" >/dev/null 2>&1 || failed+=("$name")
      fi
    done < "$file"

    if [ ${#failed[@]} -eq 0 ]; then
      ok "$label complete on retry"
      return 0
    fi
    warn "could not install: ${failed[*]}"
    return 1
  }

  rc=0
  bundle_with_fallback "$DOTFILES/Brewfile" "baseline" || rc=1

  # MacTeX is 6.4 GB and is deliberately not part of the baseline.
  if is_macos && [ "${DOTFILES_TEX:-0}" = 1 ]; then
    info "installing MacTeX (6.4 GB)"
    brew install --cask mactex || rc=1
  fi

  if is_macos && [ "${DOTFILES_APPS:-0}" = 1 ]; then
    bundle_with_fallback "$DOTFILES/Brewfile.apps" "GUI apps" || rc=1
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

  [ $rc -eq 0 ] && ok "Homebrew done" || warn "Homebrew finished with some failures"
  exit $rc
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
