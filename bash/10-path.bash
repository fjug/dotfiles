# --- environment and PATH ----------------------------------------------------

# Everything shell-agnostic lives here, shared with zsh.
[ -r "$DOTFILES/shell/env.sh" ] && . "$DOTFILES/shell/env.sh"

# Homebrew: /opt/homebrew on Apple Silicon, /usr/local on Intel,
# /home/linuxbrew on Linux. Whichever exists wins.
if [ -z "${HOMEBREW_PREFIX:-}" ]; then
  for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew \
               /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$_brew" ]; then
      eval "$("$_brew" shellenv)"
      break
    fi
  done
  unset _brew
fi
[ -n "${HOMEBREW_PREFIX:-}" ] && export BREW="$HOMEBREW_PREFIX"

_path_prepend "$HOME/bin"

# Optional, only if actually present on this machine.
_path_prepend "$HOME/reMarkable/bin"
_path_prepend "$HOME/Kobo/bin"
_path_prepend "$HOME/.opencode/bin"

# Gurobi — whatever version is installed, no hard-coded release number.
for _g in /Library/gurobi*/macos_universal2 /opt/gurobi*/linux64; do
  if [ -d "$_g/bin" ]; then
    export GUROBI_HOME="$_g"
    _path_prepend "$_g/bin"
    break
  fi
done
unset _g

# Last, so user-local binaries win over everything (including any conda).
# uv installs its tools here, and TinyTeX links pdflatex/latexmk here.
_path_prepend "$HOME/.local/bin"
