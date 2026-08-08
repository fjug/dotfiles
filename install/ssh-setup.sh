#!/usr/bin/env bash
# Prepare ~/.ssh on a new machine: fix permissions, then load every private
# key into the agent.
#
# This does NOT create or copy keys — they have to come across from the old
# machine over an encrypted channel, or be generated with ssh-keygen. Run this
# afterwards.
#
# Safe to re-run.

set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES/install/lib.sh"

SSH_DIR="$HOME/.ssh"

[ -d "$SSH_DIR" ] || { mkdir -p "$SSH_DIR"; ok "created $SSH_DIR"; }
chmod 700 "$SSH_DIR"

# --- config ------------------------------------------------------------------
if [ ! -f "$SSH_DIR/config" ]; then
  warn "no ~/.ssh/config yet — start from the template:"
  printf '        cp %s/ssh/config.example %s/config\n' "$DOTFILES" "$SSH_DIR"
fi

# --- permissions -------------------------------------------------------------
# Private keys and anything that isn't a public key must be owner-only. ssh
# refuses to use a key that other users can read.
info "fixing permissions"
shopt -s nullglob
for f in "$SSH_DIR"/*; do
  [ -f "$f" ] || continue
  case "$f" in
    *.pub) chmod 644 "$f" ;;
    *)     chmod 600 "$f" ;;
  esac
done
ok "~/.ssh is 700, keys and secrets are 600, public keys are 644"

# --- load keys ---------------------------------------------------------------
# Every private key, not just id_rsa. On this setup `ht` is the key the HPC,
# VDI and deNBI hosts know, and the one GitHub authenticates with.
KEY_NAMES=(ht id_ed25519 id_rsa id_ecdsa)

keys=()
for name in "${KEY_NAMES[@]}"; do
  [ -f "$SSH_DIR/$name" ] && keys+=("$SSH_DIR/$name")
done

# Pick up anything else that looks like a private key and wasn't named above.
for f in "$SSH_DIR"/*; do
  [ -f "$f" ] || continue
  case "$f" in *.pub|*/config|*/known_hosts*|*/environment-*|*.txt|*.json|*.ppk) continue ;; esac
  head -1 "$f" 2>/dev/null | grep -q "PRIVATE KEY" || continue
  [[ " ${keys[*]-} " == *" $f "* ]] || keys+=("$f")
done

if [ ${#keys[@]} -eq 0 ]; then
  warn "no private keys found in $SSH_DIR — copy them over, then re-run this"
  exit 0
fi

info "adding ${#keys[@]} key(s) to the agent"
# stderr is deliberately NOT redirected: a passphrase-protected key prompts
# here, and swallowing that would make it look like a silent failure.
for k in "${keys[@]}"; do
  if is_macos; then
    # Stores the passphrase in the login keychain, so it is asked for once.
    ssh-add --apple-use-keychain "$k" && ok "${k##*/}" \
      || warn "could not add ${k##*/}"
  else
    ssh-add "$k" && ok "${k##*/}" || warn "could not add ${k##*/}"
  fi
done

echo
info "agent now holds:"
ssh-add -l || true

# --- secrets that shouldn't live here ----------------------------------------
strays=()
for f in "$SSH_DIR"/*.txt "$SSH_DIR"/*.json; do
  [ -f "$f" ] && strays+=("${f##*/}")
done
if [ ${#strays[@]} -gt 0 ]; then
  echo
  warn "${#strays[@]} non-SSH secret(s) are sitting in ~/.ssh:"
  printf '        %s\n' "${strays[@]}"
  warn "recovery codes, API keys and OAuth secrets belong in a password manager."
fi
