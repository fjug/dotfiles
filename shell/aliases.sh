# Aliases shared by zsh and bash.
#
# Everything in here must be valid in BOTH shells, and in bash 3.2 (what macOS
# ships) as well as bash 5.x. That means printf instead of `print`, no zsh glob
# qualifiers, and no [[ ]] constructs either shell lacks.
#
# Shell-specific aliases live in zsh/50-aliases.zsh and bash/50-aliases.bash.

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
command -v bat     >/dev/null 2>&1 && alias cat='bat --paging=never --style=plain' && alias catp='command cat'
command -v btop    >/dev/null 2>&1 && alias top='btop'
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
# Guardrail, not a wall: bare `pip` nudges you to uv, `realpip` runs the real
# thing. `pip!` does too, but only in zsh — in bash the trailing `!` collides
# with history expansion.
#
# Only on machines WITHOUT conda. The Linux/VDI boxes still depend on conda,
# and blocking pip there would be actively wrong. Tested by path as well as by
# `command -v`, because bash initialises conda after this file is sourced.
alias realpip='command pip'
if ! command -v conda > /dev/null 2>&1 \
   && [ ! -x "$HOME/miniconda3/bin/conda" ] \
   && [ ! -x /localscratch/miniconda3/bin/conda ]; then
  alias pip='printf "%s\n" "This setup is uv-only — try: uv add <pkg> / uv pip install <pkg>" "(use realpip to force the real pip)" >&2; false'
  alias conda='printf "%s\n" "conda is not installed, and this setup prefers uv. See docs/conda-to-uv.md." >&2; false'
fi

# Everyday
if [ -n "${IS_LINUX:-}" ]; then
  alias myip='hostname -I'
else
  alias myip='ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | cut -d" " -f2'
fi
alias today='date "+%Y-%m-%d %H:%M (%A)"'
alias dotfiles='cd $DOTFILES'
alias please='sudo $(fc -ln -1) && echo "Okay..."'

# macOS only
case "$OSTYPE" in
  darwin*)
    alias preview='open -a Preview'
    alias safari='open -a Safari'
    alias o='open'
    alias ofd='open "$PWD"'                     # from the omz `macos` plugin
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'
    ;;
esac

# Remote hosts — the matching Host entries live in ~/.ssh/config
# (see ssh/config.example for a sanitised template).
alias deNBI='ssh -p 30253 -i ~/.ssh/ht ubuntu@129.70.51.6'
alias deNBI8888='ssh -p 30253 -i ~/.ssh/ht ubuntu@129.70.51.6 -L 8888:localhost:8888'
alias scpdeNBI='scp -i ~/.ssh/ht -P 30253'

# --- carried over from the Linux setup --------------------------------------

# common git typos
alias giot='git'
alias goit='git'
alias got='git'
alias gti='git'

alias vi='vim'
alias mv='mv -i'                      # prompt before clobbering
alias cls='clear; pwd; ls'
alias f='find . -name'
alias grep='grep --color=auto'        # BSD and GNU grep both accept this
alias cgrep='grep --color=always'
alias rgrep='grep -IR'
alias cdiff='colordiff 2> /dev/null'
alias histime='HISTTIMEFORMAT="%F %T " history'

# in-place sed, spelled consistently across BSD (macOS) and GNU (Linux)
if [ -n "${IS_MACOSX:-}" ]; then
  alias sedi="sed -i ''"
else
  alias sedi="sed -i''"
fi
alias detab="sedi -e 's/\t/  /g'"

# open a file manager for a folder
if [ -n "${IS_MACOSX:-}" ]; then
  alias start='open'
  alias eject='diskutil eject'
  command -v ldd > /dev/null 2>&1 || alias ldd='otool -L'
elif [ -n "${IS_LINUX:-}" ]; then
  command -v nautilus > /dev/null 2>&1 && alias start='nautilus'
fi
