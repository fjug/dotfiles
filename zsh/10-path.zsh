# --- PATH --------------------------------------------------------------------
# `typeset -U path` keeps entries unique, so re-sourcing never duplicates.

typeset -U path PATH

# Homebrew: /opt/homebrew on Apple Silicon, /usr/local on Intel,
# /home/linuxbrew on Linux. Whichever exists wins.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [ -x "$_brew" ]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew

path=(
  "$HOME/bin"
  "$HOME/.local/bin"          # uv installs tools here
  $path
)

# Optional, only if actually present on this machine.
[ -d "$HOME/reMarkable/bin" ] && path=("$HOME/reMarkable/bin" $path)
[ -d "$HOME/Kobo/bin" ]       && path=("$HOME/Kobo/bin" $path)

# Gurobi — picks up whatever version is installed, no hard-coded 9.5.1.
for _gurobi in /Library/gurobi*/macos_universal2(N) /opt/gurobi*/linux64(N); do
  if [ -d "$_gurobi/bin" ]; then
    export GUROBI_HOME="$_gurobi"
    path=("$GUROBI_HOME/bin" $path)
    break
  fi
done
unset _gurobi

export PATH
