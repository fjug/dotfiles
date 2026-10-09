#!/usr/bin/env bash
# Self-test for this repo. Run it locally before pushing; CI runs the same
# script, so a green CI means exactly what a green local run means.
#
#   install/selftest.sh
#
# Checks, in order:
#   1. every shell file parses under every shell that will read it, including
#      the bash 3.2 macOS ships
#   2. link.sh works against a throwaway $HOME and produces the expected links
#   3. zsh and bash both start interactively without emitting errors
#   4. doctor.sh runs to completion
#
# Exit status is the number of failed checks, so 0 means clean.

set -uo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$DOTFILES" || exit 1

FAILED=0
pass() { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; FAILED=$((FAILED + 1)); }
head_() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

# --- 1. syntax ---------------------------------------------------------------
# Files are grouped by which shells actually read them. The shared shell/
# directory is the important one: it must parse everywhere, and that is the
# drift this repo has been bitten by before.
BASH_FILES=$(printf '%s\n' bootstrap.sh link.sh install/*.sh bash/*.bash .bashrc .bash_profile)
ZSH_FILES=$(printf '%s\n' .zshrc .zshenv zsh/*.zsh)
SHARED_FILES=$(printf '%s\n' shell/*.sh)

head_ "syntax: bash files"
for b in /bin/bash /opt/homebrew/bin/bash /usr/local/bin/bash bash; do
  command -v "$b" >/dev/null 2>&1 || continue
  ver=$("$b" --version | head -1 | sed -E 's/.*version ([0-9]+\.[0-9]+).*/\1/')
  errs=0
  for f in $BASH_FILES $SHARED_FILES; do
    [ -r "$f" ] || continue
    "$b" -n "$f" 2>/dev/null || { bad "bash $ver: $f"; errs=1; }
  done
  [ "$errs" -eq 0 ] && pass "bash $ver ($b): all files parse"
done

head_ "syntax: zsh files"
if command -v zsh >/dev/null 2>&1; then
  errs=0
  for f in $ZSH_FILES $SHARED_FILES; do
    [ -r "$f" ] || continue
    zsh -n "$f" 2>/dev/null || { bad "zsh: $f"; errs=1; }
  done
  [ "$errs" -eq 0 ] && pass "zsh $(zsh --version | awk '{print $2}'): all files parse"
else
  bad "zsh not installed"
fi

# --- 2. link.sh against a throwaway HOME -------------------------------------
head_ "link.sh"
TESTHOME=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-selftest.XXXXXX") || exit 1
trap 'rm -rf "$TESTHOME"' EXIT
if HOME="$TESTHOME" XDG_CONFIG_HOME="$TESTHOME/.config" \
   XDG_DATA_HOME="$TESTHOME/.local/share" XDG_CACHE_HOME="$TESTHOME/.cache" \
   bash "$DOTFILES/link.sh" >"$TESTHOME/link.log" 2>&1; then
  pass "link.sh ran"
else
  bad "link.sh failed"; sed 's/^/      /' "$TESTHOME/link.log"
fi
for f in .zshrc .zshenv .bashrc .bash_profile .inputrc .gitconfig .vimrc; do
  if [ -L "$TESTHOME/$f" ] && [ -e "$TESTHOME/$f" ]; then
    :
  else
    bad "link.sh did not create a working $f"
  fi
done
[ -L "$TESTHOME/.config/starship.toml" ] || bad "link.sh did not link starship.toml"
pass "expected symlinks present"

# --- 3. interactive start ----------------------------------------------------
# The patterns below are what a broken module actually prints. This is how the
# `shopt: autocd: invalid shell option name` regression in macOS's bash 3.2
# would have been caught.
NOISE='command not found|parse error|syntax error|bad substitution|invalid shell option|unbound variable|No such file or directory|cannot be opened|_cached_init:|not valid'

check_interactive() {
  local label="$1" sh="$2" log
  log="$TESTHOME/$label.err"
  HOME="$TESTHOME" XDG_CONFIG_HOME="$TESTHOME/.config" \
  XDG_DATA_HOME="$TESTHOME/.local/share" XDG_CACHE_HOME="$TESTHOME/.cache" \
  LANG=C.UTF-8 "$sh" -i -c 'exit' 2>"$log" >/dev/null
  # Runner terminals are not ttys, so job-control and ioctl notices are normal.
  if grep -aiE "$NOISE" "$log" \
       | grep -avE 'job control|ioctl|setlocale|terminal process group' \
       | grep -aq .; then
    bad "$label printed errors on start:"
    grep -aiE "$NOISE" "$log" | grep -avE 'job control|ioctl|setlocale|terminal process group' | head -5 | sed 's/^/      /'
  else
    pass "$label starts clean"
  fi
}

head_ "interactive start"
for b in /bin/bash /opt/homebrew/bin/bash; do
  [ -x "$b" ] && check_interactive "bash $("$b" --version | head -1 | sed -E 's/.*version ([0-9]+\.[0-9]+).*/\1/')" "$b"
done
command -v zsh >/dev/null 2>&1 && check_interactive zsh "$(command -v zsh)"

# --- 4. doctor ---------------------------------------------------------------
# It is expected to report missing tools on a bare runner; it must not crash.
head_ "doctor.sh"
if HOME="$TESTHOME" bash "$DOTFILES/install/doctor.sh" >"$TESTHOME/doctor.log" 2>&1; then
  pass "doctor.sh ran (clean)"
elif grep -q "problem(s)" "$TESTHOME/doctor.log"; then
  pass "doctor.sh ran and reported problems, as expected on a bare machine"
else
  bad "doctor.sh crashed"; tail -5 "$TESTHOME/doctor.log" | sed 's/^/      /'
fi

# --- summary -----------------------------------------------------------------
echo
if [ "$FAILED" -eq 0 ]; then
  printf '\033[32mall checks passed\033[0m\n'
else
  printf '\033[31m%d check(s) failed\033[0m\n' "$FAILED"
fi
exit "$FAILED"
