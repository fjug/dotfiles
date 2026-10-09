#!/usr/bin/env bash
# Report what is and isn't set up on this machine, and how to fix each gap.
# Read-only: changes nothing.

set -uo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES/install/lib.sh"
set +e

PROBLEMS=()

pass() { printf '  %s✓%s %s\n' "$_c_green" "$_c_off" "$*"; }
fail() { printf '  %s✗%s %s\n' "$_c_red" "$_c_off" "$1"; PROBLEMS+=("$2"); }

echo
info "dotfiles doctor — $OS, repo at $DOTFILES"

# --- 1. symlinks --------------------------------------------------------------
echo
info "symlinks"
for pair in \
  ".zshenv:$HOME/.zshenv" \
  ".zshrc:$HOME/.zshrc" \
  ".bashrc:$HOME/.bashrc" \
  ".bash_profile:$HOME/.bash_profile" \
  ".inputrc:$HOME/.inputrc" \
  ".gitconfig:$HOME/.gitconfig" \
  ".vimrc:$HOME/.vimrc"
do
  src="$DOTFILES/${pair%%:*}"; dst="${pair##*:}"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    pass "${dst##*/}"
  else
    fail "${dst##*/} is not linked" "bash $DOTFILES/link.sh"
  fi
done

# --- 2. Homebrew --------------------------------------------------------------
echo
info "homebrew"
if load_brew; then
  pass "brew at $(command -v brew)"
  # Was the baseline actually installed?
  missing=()
  for f in git gh uv starship eza bat ripgrep fd fzf zoxide git-delta lazygit jq zsh; do
    brew list --formula "$f" >/dev/null 2>&1 || missing+=("$f")
  done
  if [ ${#missing[@]} -eq 0 ]; then
    pass "baseline formulae present"
  else
    fail "missing formulae: ${missing[*]}" "bash $DOTFILES/install/packages.sh"
  fi
else
  fail "Homebrew is not installed" "bash $DOTFILES/install/packages.sh"
fi

# --- 3. PATH ------------------------------------------------------------------
# The most common confusion: things ARE installed, but this shell can't see
# them because no ~/.zshenv/.zshrc was in place when it started.
echo
info "PATH"
brew_bin="${HOMEBREW_PREFIX:-/opt/homebrew}/bin"
if [ -d "$brew_bin" ]; then
  case ":$PATH:" in
    *":$brew_bin:"*) pass "$brew_bin is on PATH" ;;
    *) fail "$brew_bin exists but is NOT on this shell's PATH" \
            "open a new terminal after running link.sh (or: exec zsh)" ;;
  esac
fi
case ":$PATH:" in
  *":$HOME/.local/bin:"*) pass "~/.local/bin is on PATH" ;;
  *) fail "~/.local/bin is not on PATH (uv tools live there)" \
          "open a new terminal after running link.sh" ;;
esac

# --- 4. tools -----------------------------------------------------------------
echo
info "tools"
for t in zsh git gh uv starship eza bat rg fd fzf zoxide delta lazygit; do
  if command -v "$t" >/dev/null 2>&1; then
    pass "$(printf '%-10s %s' "$t" "$(command -v "$t")")"
  else
    fail "$t not found" "bash $DOTFILES/install/packages.sh"
  fi
done

# --- 5. python ----------------------------------------------------------------
echo
info "python"
if command -v uv >/dev/null 2>&1; then
  pass "uv $(uv --version 2>/dev/null | awk '{print $2}')"
  if uv python list 2>/dev/null | grep -q 'uv/python'; then
    pass "uv-managed interpreters installed"
  else
    fail "no uv-managed interpreters" "bash $DOTFILES/install/python-uv.sh"
  fi
else
  fail "uv not installed" "bash $DOTFILES/install/python-uv.sh"
fi
for d in "$HOME/miniconda3" "$HOME/anaconda3" "$HOME/miniforge3"; do
  [ -d "$d" ] && warn "conda present at $d — this setup is uv-only (docs/conda-to-uv.md)"
done

# --- 6. shell -----------------------------------------------------------------
echo
info "shell"
zsh_path="$(preferred_zsh)"
login_shell="$(current_login_shell)"
login_shell="${login_shell:-${SHELL:-unknown}}"
if [ "$login_shell" = "$zsh_path" ]; then
  pass "login shell is $login_shell"
else
  fail "login shell is $login_shell, not $zsh_path" \
       "sudo sh -c 'echo $zsh_path >> /etc/shells' && chsh -s $zsh_path"
fi
# bash: the config is shared, so it should load cleanly even though zsh is
# the login shell.
bash_path="${HOMEBREW_PREFIX:-/opt/homebrew}/bin/bash"
[ -x "$bash_path" ] || bash_path="$(command -v bash)"
bash_ver="$("$bash_path" --version 2>/dev/null | head -1 | sed -E 's/.*version ([0-9]+)\.([0-9]+).*/\1.\2/')"
case "$bash_ver" in
  3.*) fail "bash is $bash_ver ($bash_path) — macOS's 2007 build" \
            "brew install bash" ;;
  "")  fail "no bash found" "brew install bash" ;;
  *)   pass "bash $bash_ver at $bash_path" ;;
esac
if "$bash_path" -ic 'exit' 2>&1 | grep -qiE 'error|not found|unbound'; then
  fail "interactive bash reports errors" "$bash_path -ic exit   # to see them"
else
  pass "interactive bash starts clean"
fi

plugin_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
n=$(ls -1 "$plugin_dir" 2>/dev/null | wc -l | tr -d ' ')
if [ "${n:-0}" -ge 4 ]; then
  pass "$n zsh plugins cloned"
else
  fail "zsh plugins not cloned ($n/4)" "start an interactive zsh once: zsh -i"
fi

# --- 7. ssh -------------------------------------------------------------------
echo
info "ssh"
[ -f "$HOME/.ssh/config" ] && pass "~/.ssh/config present" \
  || fail "no ~/.ssh/config" "cp $DOTFILES/ssh/config.example ~/.ssh/config"
if [ -f "$HOME/.ssh/ht" ]; then
  pass "key 'ht' present"
  ssh-add -l 2>/dev/null | grep -q . && pass "agent has keys loaded" \
    || fail "no keys in the agent" "bash $DOTFILES/install/ssh-setup.sh"
else
  fail "key 'ht' not present — it is the one the HPC/VDI/GitHub hosts know" \
       "copy it from the old machine, then: bash $DOTFILES/install/ssh-setup.sh"
fi

# --- summary ------------------------------------------------------------------
echo
if [ ${#PROBLEMS[@]} -eq 0 ]; then
  printf '  %severything checks out%s\n\n' "$_c_green" "$_c_off"
  exit 0
fi

printf '  %s%d problem(s)%s — suggested fixes, in order:\n\n' \
  "$_c_red" "${#PROBLEMS[@]}" "$_c_off"
printf '%s\n' "${PROBLEMS[@]}" | awk '!seen[$0]++ {print "    " $0}'
echo
exit 1
