# --- completion --------------------------------------------------------------

# bash-completion is not loaded by /etc/profile.d for non-login shells (VS Code
# terminals, for instance), and on macOS it comes from Homebrew.
if [ -z "${BASH_COMPLETION_VERSINFO:-}" ]; then
  for _bc in \
    "${BREW:-/nonexistent}/etc/profile.d/bash_completion.sh" \
    "${BREW:-/nonexistent}/etc/bash_completion" \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion
  do
    if [ -r "$_bc" ]; then
      . "$_bc"
      break
    fi
  done
  unset _bc
fi

# expand variables in directory completion instead of escaping the '$'
shopt -s direxpand 2> /dev/null

# __git_ps1, for the fallback prompt when starship is not installed.
if ! command -v __git_ps1 > /dev/null 2>&1; then
  for _gp in \
    "${BREW:-/nonexistent}/etc/bash_completion.d/git-prompt.sh" \
    /Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh \
    /usr/share/git-core/contrib/completion/git-prompt.sh \
    /etc/bash_completion.d/git-prompt \
    /usr/lib/git-core/git-sh-prompt
  do
    if [ -r "$_gp" ]; then
      . "$_gp"
      break
    fi
  done
  unset _gp
fi

# Completions for uv, uvx and gh are generated once into the bash-completion
# user directory, so bash-completion lazy-loads them on first <Tab> instead of
# three process spawns on every single shell start. Regenerated when the
# binary is newer than the cached file.
_bcd="${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion}/completions"
for _c in "uv generate-shell-completion bash" \
          "uvx --generate-shell-completion bash" \
          "gh completion -s bash"; do
  _b="${_c%% *}"
  _bin "$_b" || continue
  if [ ! -s "$_bcd/$_b" ] || [ "$REPLY" -nt "$_bcd/$_b" ]; then
    mkdir -p "$_bcd" && $_c > "$_bcd/$_b" 2> /dev/null
  fi
done
unset _bcd _c _b
