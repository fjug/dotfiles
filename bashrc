# --== ssh-agent ==--

# On Linux, share one systemd user ssh-agent across all shells, unless an
# agent is already provided (e.g. forwarded). Keys are added on first use
# via 'AddKeysToAgent yes' in ~/.ssh/config, or with 'ssh-add ~/.ssh/ht'.
# Placed before the interactive check so non-interactive shells get it too.
if [ -z "$SSH_AUTH_SOCK" ] && [ -n "$XDG_RUNTIME_DIR" ] && command -v systemctl > /dev/null 2>&1; then
	if [ ! -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]; then
		systemctl --user start ssh-agent.service > /dev/null 2>&1
	fi
	[ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ] && \
		export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# User-local binaries (e.g. TinyTeX links pdflatex/latexmk here) must also be
# on PATH for non-interactive shells, such as the VS Code server.
case ":$PATH:" in
	*":$HOME/.local/bin:"*) ;;
	*) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# if not running interactively, don't do anything
[ -z "$PS1" ] && return

export DOTFILES=~/GIT/dotfiles

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot)
fi

# --== bash completion ==--

if [ -f /etc/bash_completion ]; then
	# Ubuntu Linux
	. /etc/bash_completion

	# NB: Workaround for environment variable expansion bug in bash 4.2+.
	# See: http://askubuntu.com/q/41891
	if ((BASH_VERSINFO[0] >= 4)) && \
		((BASH_VERSINFO[1] >= 2)) && \
		((BASH_VERSINFO[2] >= 29))
	then
		shopt -s direxpand
	fi
fi

# --== git ==--

# enable bash completion of git commands
if [ -f /etc/bash_completion.d/git-prompt ]; then
	# newer Ubuntu Linux ("sudo aptitude install bash-completion")
	. /etc/bash_completion.d/git-prompt # in case of no /etc/bash_completion
elif [ -f /etc/bash_completion.d/git ]; then
	# older Ubuntu Linux ("sudo aptitude install bash-completion")
	# or Cygwin ("apt-cyg install bash-completion")
	. /etc/bash_completion.d/git # in case of no /etc/bash_completion
fi

# --== shell prompt ==--

SHELL_PROMPT=': ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@${HOSTNAME}\[\033[00m\] \[\033[01;34m\]\w'

if [ "$(__git_ps1 x 2> /dev/null)" = "x" ]; then
	# make shell prompt reflect current git status+branch
	PS1="$SHELL_PROMPT"'\[\033[01;32m\]$(__git_ps1)\[\033[00m\]\n'
else
	PS1="$SHELL_PROMPT"'\[\033[00m\]\n'
fi

# --== bash ==--

# use vi commands for advanced editing (hit ESC to enter command mode)
# set -o vi

# --== shell plugins ==--

for f in $DOTFILES/plugins/*.sh
do
	source $f
done

# Local customized path and environment settings, etc.
if [ -f ~/.bash_local ]; then
	. ~/.bash_local
fi


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/localscratch/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/localscratch/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/localscratch/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/localscratch/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# opencode
export PATH=/home/florian.jug/.opencode/bin:$PATH
export PATH=/home/florian.jug/.local/bin:$PATH
