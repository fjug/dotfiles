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

# Location of this repository, derived from where this file really lives
# (works via the ~/.bashrc symlink and via a config-links.sh stub alike).
# Not taken from the environment: a zsh started from ~/.dotfiles exports a
# DOTFILES that points somewhere without plugins/.
DOTFILES="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2> /dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
export DOTFILES

# prepend a directory to PATH, moving it to the front if already present
_path_prepend() {
	[ -d "$1" ] || return 0
	PATH=":$PATH:"
	PATH="${PATH//:$1:/:}"
	PATH="${PATH#:}"; PATH="${PATH%:}"
	export PATH="$1${PATH:+:$PATH}"
}

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot)
fi

# --== platform ==--

case "$(uname)" in
	Darwin)
		# Homebrew (Apple Silicon or Intel)
		for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
			if [ -x "$_brew" ]; then
				eval "$("$_brew" shellenv)"
				export BREW="$HOMEBREW_PREFIX"
				break
			fi
		done
		unset _brew
		export CLICOLOR=1
		;;
esac

_path_prepend "$HOME/bin"

# --== bash ==--

export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize cdspell 2> /dev/null

# use vi commands for advanced editing (hit ESC to enter command mode)
# set -o vi

# --== bash completion ==--

# Not loaded by /etc/profile.d for non-login shells (e.g. VS Code terminals).
if [ -z "$BASH_COMPLETION_VERSINFO" ]; then
	for _bc in \
		/usr/share/bash-completion/bash_completion \
		/etc/bash_completion \
		"${BREW:-/nonexistent}/etc/profile.d/bash_completion.sh" \
		"${BREW:-/nonexistent}/etc/bash_completion"
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

# --== git ==--

# __git_ps1 for the prompt
if ! command -v __git_ps1 > /dev/null 2>&1; then
	for _gp in \
		/usr/share/git-core/contrib/completion/git-prompt.sh \
		/etc/bash_completion.d/git-prompt \
		/usr/lib/git-core/git-sh-prompt \
		"${BREW:-/nonexistent}/etc/bash_completion.d/git-prompt.sh" \
		/Library/Developer/CommandLineTools/usr/share/git-core/git-prompt.sh
	do
		if [ -r "$_gp" ]; then
			. "$_gp"
			break
		fi
	done
	unset _gp
fi

# --== shell prompt ==--

if command -v starship > /dev/null 2>&1; then
	export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
	eval "$(starship init bash)"
else
	SHELL_PROMPT=': ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@${HOSTNAME}\[\033[00m\] \[\033[01;34m\]\w'
	if [ "$(__git_ps1 x 2> /dev/null)" = "x" ]; then
		# make shell prompt reflect current git status+branch
		PS1="$SHELL_PROMPT"'\[\033[01;32m\]$(__git_ps1)\[\033[00m\]\n'
	else
		# no git-prompt.sh available: show the bare branch name
		__branch() { git branch --show-current 2> /dev/null | sed 's/.*/ (&)/'; }
		PS1="$SHELL_PROMPT"'\[\033[01;32m\]$(__branch)\[\033[00m\]\n'
	fi
fi

# --== optional tools (each only if installed) ==--

# zoxide: 'z <fragment>' jumps to a frecent directory
command -v zoxide > /dev/null 2>&1 && eval "$(zoxide init bash)"

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd
if command -v fzf > /dev/null 2>&1; then
	if ! eval "$(fzf --bash 2> /dev/null)" 2> /dev/null || ! command -v __fzf_history__ > /dev/null 2>&1; then
		for _fz in /usr/share/fzf/shell/key-bindings.bash /usr/share/doc/fzf/examples/key-bindings.bash; do
			[ -r "$_fz" ] && . "$_fz" && break
		done
		unset _fz
	fi
	export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
	if command -v fd > /dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
		export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
		export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
	fi
fi

# uv: shell completion, generated once into the bash-completion user dir so
# it is lazy-loaded on first <Tab> instead of costing startup time
if command -v uv > /dev/null 2>&1; then
	_bcd="${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion}/completions"
	if [ ! -s "$_bcd/uv" ] || [ "$(command -v uv)" -nt "$_bcd/uv" ]; then
		mkdir -p "$_bcd" && uv generate-shell-completion bash > "$_bcd/uv" 2> /dev/null
		command -v uvx > /dev/null 2>&1 && \
			uvx --generate-shell-completion bash > "$_bcd/uvx" 2> /dev/null
	fi
	unset _bcd
fi

# gh: GitHub CLI completion
command -v gh > /dev/null 2>&1 && eval "$(gh completion -s bash 2> /dev/null)"

# --== shell plugins ==--

for f in "$DOTFILES"/plugins/*.sh
do
	[ -r "$f" ] && source "$f"
done
unset f

# Local customized path and environment settings, etc.
if [ -f ~/.bash_local ]; then
	. ~/.bash_local
fi
# (name used by the newer ~/.dotfiles setup)
if [ -f ~/.bashrc.local ]; then
	. ~/.bashrc.local
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
_path_prepend "$HOME/.opencode/bin"
# keep user-local binaries ahead of conda and everything else
_path_prepend "$HOME/.local/bin"
