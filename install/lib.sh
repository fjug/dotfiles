#!/usr/bin/env bash
# Shared helpers for the install scripts. Source this, don't run it.

set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# --- output ------------------------------------------------------------------
if [ -t 1 ]; then
  _c_blue=$'\033[1;34m'; _c_green=$'\033[1;32m'
  _c_yellow=$'\033[1;33m'; _c_red=$'\033[1;31m'; _c_off=$'\033[0m'
else
  _c_blue=""; _c_green=""; _c_yellow=""; _c_red=""; _c_off=""
fi

info()  { printf '%s==>%s %s\n' "$_c_blue"   "$_c_off" "$*"; }
ok()    { printf '%s  ok%s %s\n' "$_c_green"  "$_c_off" "$*"; }
warn()  { printf '%s  !!%s %s\n' "$_c_yellow" "$_c_off" "$*" >&2; }
die()   { printf '%serror%s %s\n' "$_c_red"   "$_c_off" "$*" >&2; exit 1; }

# --- platform ----------------------------------------------------------------
case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      die "unsupported platform: $(uname -s)" ;;
esac
export OS

is_macos() { [ "$OS" = macos ]; }
is_linux() { [ "$OS" = linux ]; }
has()      { command -v "$1" >/dev/null 2>&1; }

# Put brew on PATH for the current script, wherever it landed. Each install
# script runs in its own process, so this has to be re-done rather than
# inherited from the one before.
load_brew() {
  has brew && return 0
  local p
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [ -x "$p" ] && eval "$("$p" shellenv)" && return 0
  done
  return 1
}

# Path of the zsh we want as the login shell: Homebrew's if it exists,
# otherwise whatever the system provides.
preferred_zsh() {
  local p
  for p in "${HOMEBREW_PREFIX:-/opt/homebrew}/bin/zsh" /usr/local/bin/zsh \
           /home/linuxbrew/.linuxbrew/bin/zsh /bin/zsh /usr/bin/zsh; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  command -v zsh 2>/dev/null
}

# The login shell recorded for this user, not the one currently running.
# Keyed on the directory-service user record, NOT on $HOME: those are usually
# the same path, but when they aren't, dscl returns "Invalid Path" and the
# caller would wrongly conclude the login shell needs changing.
current_login_shell() {
  local u shell
  u="$(id -un)"
  if is_macos; then
    shell="$(dscl . -read "/Users/$u" UserShell 2>/dev/null | awk '{print $2}')"
  else
    shell="$(getent passwd "$u" 2>/dev/null | cut -d: -f7)"
  fi
  case "$shell" in
    /*) echo "$shell" ;;      # only trust an absolute path
    *)  echo "${SHELL:-}" ;;
  esac
}

# Linux package manager, if we can find one.
linux_pkg_mgr() {
  for m in apt-get dnf pacman zypper; do
    has "$m" && { echo "$m"; return 0; }
  done
  return 1
}

# --- filesystem --------------------------------------------------------------
# link <source-in-repo> <target-in-home>
# Idempotent: re-running is a no-op. Existing real files are backed up.
link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || { warn "missing in repo, skipping: $src"; return 0; }

  if [ -L "$dst" ]; then
    if [ "$(readlink "$dst")" = "$src" ]; then
      ok "$dst"
      return 0
    fi
    rm "$dst"                       # stale symlink (e.g. an old repo layout)
  elif [ -e "$dst" ]; then
    local bak="$dst.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$dst" "$bak"
    warn "existing $dst moved to $bak"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "$dst -> $src"
}

confirm() {
  [ "${DOTFILES_YES:-0}" = 1 ] && return 0
  local reply
  printf '%s [y/N] ' "$1"
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}
