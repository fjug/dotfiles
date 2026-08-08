# --- aliases -----------------------------------------------------------------

# Listing — eza if available, otherwise plain ls with the same muscle memory.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -lh'
  alias la='ls -lah'
fi

# `cat` gets syntax colour; `catp` is the untouched original.
# `grep` is deliberately NOT aliased to rg — too many POSIX flags differ.
command -v bat  >/dev/null 2>&1 && alias cat='bat --paging=never --style=plain' && alias catp='command cat'
command -v btop >/dev/null 2>&1 && alias top='btop'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cdgit='cd ~/GIT'
alias d='dirs -v'

# Git — the handful of oh-my-zsh git-plugin aliases worth keeping.
# Everything else lives as a real git alias in .gitconfig (git st, git di, ...).
alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gl='git pull'
alias glg='git log --date-order --graph --decorate --oneline'

# Python / uv — no conda, ever.
alias py='uv run python'
alias venv='uv venv'
# Guardrail, not a wall: bare `pip` nudges you to uv, `pip!` runs the real thing.
alias pip='print -u2 "This setup is uv-only — try: uv add <pkg> / uv pip install <pkg>\n(use pip! to force the real pip)"; false'
alias pip!='command pip'
alias conda='print -u2 "conda is intentionally not part of this setup — use uv."; false'

# Everyday
alias myip='ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | cut -d" " -f2'
alias today='date "+%Y-%m-%d %H:%M (%A)"'
alias zshconfig='$EDITOR $DOTFILES/.zshrc'
alias dotfiles='cd $DOTFILES'
alias please='sudo $(fc -ln -1) && echo "Okay..."'

# macOS only
if [[ "$OSTYPE" == darwin* ]]; then
  alias preview='open -a Preview'
  alias safari='open -a Safari'
  alias o='open'
  alias ofd='open "$PWD"'                       # from the omz `macos` plugin
  alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
  alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
fi

# Remote hosts — the matching Host entries live in ~/.ssh/config
# (see ssh/config.example for a sanitised template).
alias deNBI='ssh -p 30253 -i ~/.ssh/ht ubuntu@129.70.51.6'
alias deNBI8888='ssh -p 30253 -i ~/.ssh/ht ubuntu@129.70.51.6 -L 8888:localhost:8888'
alias scpdeNBI='scp -i ~/.ssh/ht -P 30253'
