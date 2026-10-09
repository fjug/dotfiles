# .zshrc — interactive shell configuration.
#
# This file is a thin loader. Everything real lives in $DOTFILES/zsh/*.zsh and
# is sourced in numeric order. To add something, drop a new file in there
# rather than growing this one.
#
# Machine-specific settings that must NOT be committed (licences, conda,
# work-only hosts) go in ~/.zshrc.local, which is sourced last.

export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

for _zfile in "$DOTFILES"/zsh/*.zsh; do
  [ -r "$_zfile" ] && source "$_zfile"
done
unset _zfile

# Machine-local overrides — not tracked by git.
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# reading tools: reMarkable + Kobo
export PATH="$HOME/reMarkable/bin:$HOME/Kobo/bin:$PATH"

# Local AI models
OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_KEEP_ALIVE=15m
