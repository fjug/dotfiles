# --- external tool integration ----------------------------------------------
# Everything here is guarded, so the shell still works on a machine where the
# tool is missing (a fresh box, or an HPC login node you don't control).

# Prompt -----------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
  eval "$(starship init zsh)"
else
  # Minimal fallback prompt: user@host, cwd, git branch.
  autoload -Uz vcs_info
  zstyle ':vcs_info:git:*' formats ' (%b)'
  precmd() { vcs_info }
  setopt PROMPT_SUBST
  PROMPT='%F{green}%n@%m%f %F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f
%B$%b '
fi

# Directory jumping — replaces the old cwd/swd/lwd bookmark functions ----------
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"   # provides `z` and `zi`
fi

# Fuzzy finder -----------------------------------------------------------------
# Ctrl-R history, Ctrl-T files, Alt-C cd.
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  command -v bat >/dev/null 2>&1 && \
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {} 2>/dev/null | head -200'"
fi

# bat --------------------------------------------------------------------------
if command -v bat >/dev/null 2>&1; then
  export BAT_THEME="ansi"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# uv — the one and only Python toolchain ---------------------------------------
if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)" 2>/dev/null
  eval "$(uvx --generate-shell-completion zsh)" 2>/dev/null
  # Let uv manage interpreters; never fall back to a system python silently.
  export UV_PYTHON_PREFERENCE=managed
fi

# gh ---------------------------------------------------------------------------
command -v gh >/dev/null 2>&1 && eval "$(gh completion -s zsh)" 2>/dev/null

# ssh-agent --------------------------------------------------------------------
# Replaces the oh-my-zsh ssh-agent plugin. On macOS the keychain holds the
# passphrases (see ssh/config.example), so nothing needs typing.
if [[ "$OSTYPE" == darwin* ]]; then
  ssh-add -l >/dev/null 2>&1 || ssh-add --apple-load-keychain >/dev/null 2>&1
else
  if [[ -z "$SSH_AUTH_SOCK" ]]; then
    eval "$(ssh-agent -s)" >/dev/null
    for _key in "$HOME"/.ssh/id_*~*.pub(N) "$HOME"/.ssh/ht(N); do
      ssh-add "$_key" >/dev/null 2>&1
    done
    unset _key
  fi
fi
