#!/usr/bin/env bash
# Set up a fresh machine from this repo.
#
#   git clone https://github.com/fjug/.dotfiles.git ~/.dotfiles
#   ~/.dotfiles/bootstrap.sh
#
# Idempotent — safe to run again on a machine that's already set up.
#
# Steps are independent: if one fails the rest still run, and the summary at
# the end says what broke and how to re-run just that piece. Symlinks go first
# on purpose, so you end up with a working shell even if every download fails.
#
# Environment switches:
#   DOTFILES_YES=1    don't ask anything, assume yes
#   DOTFILES_APPS=1   also install the GUI apps from Brewfile.apps (macOS)
#   DOTFILES_TEX=1    also install MacTeX (6.4 GB — off by default)

set -uo pipefail          # deliberately NOT -e; see run_step
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export DOTFILES
source "$DOTFILES/install/lib.sh"
set +e                    # lib.sh turns on errexit; we handle failures ourselves

FAILED=()

# run_step <label> <re-run hint> <command...>
run_step() {
  local label="$1" hint="$2"; shift 2
  echo
  info "$label"
  if "$@"; then
    ok "$label"
  else
    warn "$label FAILED — continuing with the remaining steps"
    FAILED+=("$label|$hint")
  fi
}

cat <<BANNER

  dotfiles bootstrap
  ------------------
  repo:     $DOTFILES
  platform: $OS
  python:   uv only (no conda)

BANNER

confirm "Continue?" || exit 0

# 1. symlinks ------------------------------------------------------------------
# First, and not by accident: this is instant, needs no network, and cannot
# really fail. Everything after it can, and if it does you still have a shell.
run_step "step 1/4 — symlinks" \
         "$DOTFILES/link.sh" \
         bash "$DOTFILES/link.sh"

# 2. packages ------------------------------------------------------------------
run_step "step 2/4 — packages" \
         "bash $DOTFILES/install/packages.sh" \
         bash "$DOTFILES/install/packages.sh"

# 3. python --------------------------------------------------------------------
run_step "step 3/4 — python toolchain" \
         "bash $DOTFILES/install/python-uv.sh" \
         bash "$DOTFILES/install/python-uv.sh"

# 4. shell ---------------------------------------------------------------------
echo
info "step 4/4 — shell"
load_brew || true

# Compares full paths, not just the shell name: on macOS the login shell is
# already /bin/zsh, and the point here is to move to the newer Homebrew build.
zsh_path="$(preferred_zsh)"
login_shell="$(current_login_shell)"
login_shell="${login_shell:-${SHELL:-unknown}}"

if [ -z "$zsh_path" ]; then
  warn "no zsh found — skipping login shell setup"
elif [ "$login_shell" = "$zsh_path" ]; then
  ok "login shell is already $zsh_path"
else
  zsh_ver="$("$zsh_path" --version 2>/dev/null | awk '{print $2}')"
  info "login shell is $login_shell; $zsh_path is zsh $zsh_ver"
  if confirm "Switch the login shell to $zsh_path?"; then
    grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    # chsh asks for your password; it cannot be scripted away.
    if chsh -s "$zsh_path"; then
      ok "login shell set — takes effect in a new terminal"
    else
      warn "chsh failed"
      FAILED+=("login shell|chsh -s $zsh_path")
    fi
  fi
fi

# Plugins clone themselves on the first interactive start; do it now so the
# first real shell doesn't stall.
echo
info "pre-fetching zsh plugins"
"${zsh_path:-zsh}" -i -c 'exit' >/dev/null 2>&1 \
  || warn "first zsh start reported an issue — run 'zsh -i' to see it"

# --- summary ------------------------------------------------------------------
echo
if [ ${#FAILED[@]} -eq 0 ]; then
  printf '  %sall steps completed%s\n' "$_c_green" "$_c_off"
else
  printf '  %s%d step(s) failed%s — re-run just those:\n\n' \
    "$_c_red" "${#FAILED[@]}" "$_c_off"
  for entry in "${FAILED[@]}"; do
    printf '    %-28s  %s\n' "${entry%%|*}" "${entry##*|}"
  done
  printf '\n  Diagnose everything at once with:\n    %s/install/doctor.sh\n' "$DOTFILES"
fi

cat <<NEXT

  Next, by hand:
    - open a new terminal (or: exec zsh)
    - ssh: copy your private keys across (ht is the one that matters — it is
      what the HPC/VDI/deNBI hosts and GitHub know), then
        cp $DOTFILES/ssh/config.example ~/.ssh/config   # and edit
        $DOTFILES/install/ssh-setup.sh                  # perms + load keys
    - gh auth login
    - GUI apps:  brew bundle --file=$DOTFILES/Brewfile.apps
    - LaTeX:     brew install --cask mactex             # 6.4 GB, not automatic
    - macOS prefs: $DOTFILES/install/macos-defaults.sh
    - see docs/NEW-MACHINE.md for the full checklist

NEXT
