# --- conda (Linux boxes only) ------------------------------------------------
# This repo's Python story is uv (see docs/conda-to-uv.md), and the Macs have
# no conda at all. The VDI and HPC machines still depend on it, so the init is
# kept here — fully guarded, so it costs a conda-free machine nothing, not
# even a fork.
#
# Numbered 90 so it runs after everything else, then re-prepends
# ~/.local/bin at the end: conda's init puts its own bin directory in front
# of PATH, and uv's tools must stay ahead of conda's python.

for _conda_root in /localscratch/miniconda3 "$HOME/miniconda3"; do
  [ -x "$_conda_root/bin/conda" ] || continue
  __conda_setup="$("$_conda_root/bin/conda" 'shell.bash' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  elif [ -f "$_conda_root/etc/profile.d/conda.sh" ]; then
    . "$_conda_root/etc/profile.d/conda.sh"
  else
    _path_prepend "$_conda_root/bin"
  fi
  unset __conda_setup
  break
done
unset _conda_root

# Keep user-local binaries (uv tools, TinyTeX) ahead of conda's python.
_path_prepend "$HOME/.local/bin"
