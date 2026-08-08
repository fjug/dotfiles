# .bashrc — minimal fallback for machines where zsh isn't available
# (HPC login nodes, VDI boxes, containers). The real setup is .zshrc.

# Interactive shells only.
case $- in *i*) ;; *) return ;; esac

export DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER=less
export LESS='-R -F -X'

# History
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize cdspell 2>/dev/null

set -o vi

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

export CLICOLOR=1
export LSCOLORS=dxfxcxdxbxegedabagacad
alias ls='ls --color=auto 2>/dev/null || ls'
alias ll='ls -lh'
alias la='ls -lah'
alias ..='cd ..'
alias ...='cd ../..'
alias myip='ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1'
alias today='date "+%Y-%m-%d %H:%M (%A)"'
alias g='git'
alias gst='git status'

# Prompt with git branch, no external dependencies.
__branch() { git branch --show-current 2>/dev/null | sed 's/.*/ (&)/'; }
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;35m\]$(__branch)\[\033[00m\]\$ '

[ -r "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
