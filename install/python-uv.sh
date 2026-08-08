#!/usr/bin/env bash
# Python toolchain — uv, and nothing else.
#
# Deliberately absent: conda, miniconda, mamba, pyenv, and any `pip install
# --user`. If you find yourself reaching for one of those, the answer is
# `uv venv` + `uv add`, or `uvx <tool>` for a one-off.

set -euo pipefail
DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$DOTFILES/install/lib.sh"

# --- refuse to build on top of a conda install -------------------------------
if [ -d "$HOME/miniconda3" ] || [ -d "$HOME/anaconda3" ] || [ -d "$HOME/miniforge3" ]; then
  warn "a conda installation exists in \$HOME — this setup is uv-only."
  warn "see docs/conda-to-uv.md for how to migrate and remove it."
fi

# --- uv ----------------------------------------------------------------------
if has uv; then
  info "uv already installed; updating"
  uv self update || brew upgrade uv || true
elif has brew; then
  info "installing uv via Homebrew"
  brew install uv
else
  info "installing uv via the official installer"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

ok "uv $(uv --version | awk '{print $2}')"

# --- interpreters ------------------------------------------------------------
# uv downloads and manages these; no system Python is touched.
info "installing managed Python interpreters"
uv python install 3.11 3.12 3.13
uv python list

# --- global CLI tools --------------------------------------------------------
# Installed as isolated tools (each in its own venv, on $PATH via ~/.local/bin)
# rather than into a shared environment.
info "installing global Python tools"
tools=(
  ruff            # linter + formatter
  ipython         # better REPL
  jupyterlab      # notebooks, without a conda env in sight
  pre-commit
  httpie
  yt-dlp          # replaces the hand-downloaded ~/bin/yt-dlp_macos
)
for t in "${tools[@]}"; do
  uv tool install --quiet "$t" && ok "$t" || warn "failed: $t"
done

uv tool update-shell 2>/dev/null || true

info "done — new project: \`uv init myproj && cd myproj && uv add numpy\`"
