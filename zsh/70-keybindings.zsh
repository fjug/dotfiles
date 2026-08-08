# --- key bindings ------------------------------------------------------------
# Loaded last so it can bind widgets defined by the plugins above.

# vi editing mode (you had `set -o vi` in bash and the omz vi-mode plugin).
bindkey -v
export KEYTIMEOUT=1                       # no lag on ESC

# ...but keep the emacs-style movement keys that are muscle memory anyway.
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^K' kill-line
bindkey '^U' backward-kill-line
bindkey '^W' backward-kill-word
bindkey '^?' backward-delete-char         # backspace works past the insert point
bindkey '^H' backward-delete-char

# History search on the arrow keys, scoped to what you've already typed.
if (( $+widgets[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi

# Ctrl-R is fzf's history search when fzf is installed (see 40-tools.zsh);
# without fzf, fall back to zsh's own incremental search — the ^R/^S pair
# you were using before.
if ! command -v fzf >/dev/null 2>&1; then
  bindkey '^R' history-incremental-pattern-search-backward
  bindkey '^S' history-incremental-pattern-search-forward
fi

# Accept the autosuggestion with the right arrow / Ctrl-Space.
bindkey '^ ' autosuggest-accept

# Show the vi mode in the cursor shape: block in command mode, bar in insert.
_set_cursor() {
  case $KEYMAP in
    vicmd) printf '\e[1 q' ;;
    *)     printf '\e[5 q' ;;
  esac
}
zle-keymap-select() { _set_cursor }
zle-line-init()     { _set_cursor }
zle -N zle-keymap-select
zle -N zle-line-init
