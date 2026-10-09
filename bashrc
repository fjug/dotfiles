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
# (The usual location is checked first with a fork-free test: on the VDI every
# fork can cost ~0.1 s when the user's CPU quota is busy.)
if [ "${BASH_SOURCE[0]}" -ef "$HOME/GIT/dotfiles/bashrc" ]; then
	DOTFILES="$HOME/GIT/dotfiles"
else
	DOTFILES="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" 2> /dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
fi
export DOTFILES

# _bin <cmd>: set REPLY to the full path of <cmd> on PATH, without forking
_bin() {
	REPLY=
	hash "$1" 2> /dev/null && REPLY="${BASH_CMDS[$1]}"
	[ -n "$REPLY" ]
}

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

case "$OSTYPE" in
	darwin*)
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

# (bash equivalents of the Mac's zsh/00-options.zsh)
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups   # HIST_IGNORE_ALL_DUPS + HIST_IGNORE_SPACE
export HISTTIMEFORMAT='%F %T '            # EXTENDED_HISTORY (timestamps)
shopt -s histappend checkwinsize cdspell 2> /dev/null
shopt -s histverify                       # HIST_VERIFY: show !! expansions first
shopt -s autocd                           # AUTO_CD: a bare directory name cd's
shopt -s extglob globstar nocaseglob      # EXTENDED_GLOB, NO_CASE_GLOB
# INC_APPEND_HISTORY: write each command as it runs (starship keeps this)
case ";$PROMPT_COMMAND;" in
	*"history -a"*) ;;
	*) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
# unsetopt FLOW_CONTROL: free up ^S / ^Q
[ -t 0 ] && stty -ixon 2> /dev/null

# vi editing mode, as on the Mac (bindkey -v); ~/.inputrc keeps the emacs
# movement keys in insert mode and switches the cursor shape per mode
set -o vi

# colours for ls *and* eza, identical to the Mac (zsh/00-options.zsh)
export LS_COLORS='di=33:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# coloured man pages (replaces the oh-my-zsh colored-man-pages plugin)
man() {
	LESS_TERMCAP_md=$'\e[1;34m' \
	LESS_TERMCAP_me=$'\e[0m' \
	LESS_TERMCAP_us=$'\e[4;32m' \
	LESS_TERMCAP_ue=$'\e[0m' \
	LESS_TERMCAP_so=$'\e[1;33;44m' \
	LESS_TERMCAP_se=$'\e[0m' \
	command man "$@"
}

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

# --== cached tool init ==--

# _cached_init <name> "<dep files>" <cmd> [args...]: source the shell code
# that <cmd> prints, cached in ~/.cache/bash-init/<name>.bash. Process spawns
# are slow on the VDI, and running starship/fzf/zoxide init on every shell
# cost ~100 ms. The cache is rebuilt when it is missing or a dep file is
# newer; install-linux-tools.sh clears it after installing a new version.
_cached_init() {
	local name="$1" deps="$2" f="${XDG_CACHE_HOME:-$HOME/.cache}/bash-init/$1.bash" d stale=
	shift 2
	[ -s "$f" ] || stale=1
	for d in $deps; do [ "$d" -nt "$f" ] && stale=1; done
	if [ -n "$stale" ]; then
		mkdir -p "${f%/*}" || return 1
		if ! "$@" > "$f.$$" 2> /dev/null; then
			command rm -f "$f.$$"
			return 1
		fi
		mv -f "$f.$$" "$f"
	fi
	. "$f"
}

# starship's bash init, made cheaper (only used through the cache above):
# `starship time` (one spawn at startup plus two per command) becomes bash's
# own $EPOCHREALTIME in ms, and the continuation prompt PS2 is computed once
# instead of on every startup. If a future starship prints different init
# code, the substitutions simply do not match and nothing changes.
_starship_init() {
	local exe init
	exe="$(command -v starship)" || return 1
	init="$("$exe" init bash --print-full-init)" || return 1
	init="${init//"\$($exe time)"/'$(( ${EPOCHREALTIME//[!0-9]/} / 1000 ))'}"
	init="${init//"$exe time"/'echo $(( ${EPOCHREALTIME//[!0-9]/} / 1000 ))'}"
	init="${init//$'\n'"PS2=\"\$($exe prompt --continuation)\""/}"
	printf '%s\n' "$init"
	printf 'PS2=%q\n' "$(STARSHIP_SHELL=bash "$exe" prompt --continuation)"
}

# --== shell prompt ==--

if command -v starship > /dev/null 2>&1; then
	export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
	# no "scan timed out" warnings in the prompt on a CPU-throttled VDI/NFS home
	export STARSHIP_LOG=error
	_bin starship && _cached_init starship "$REPLY $STARSHIP_CONFIG" _starship_init
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
_bin zoxide && _cached_init zoxide "$REPLY" zoxide init bash

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd
if command -v fzf > /dev/null 2>&1; then
	if ! { _bin fzf && _cached_init fzf "$REPLY" fzf --bash; } || ! command -v __fzf_history__ > /dev/null 2>&1; then
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
	command -v bat > /dev/null 2>&1 && \
		export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {} 2>/dev/null | head -200'"
fi

# bat: man pages through bat (the theme is in ~/.config/bat/config)
command -v bat > /dev/null 2>&1 && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# uv: let uv manage interpreters (as on the Mac). Conda envs still work:
# an activated conda env takes priority for `uv pip`.
command -v uv > /dev/null 2>&1 && export UV_PYTHON_PREFERENCE=managed

# Completions for uv, uvx and gh: generated once into the bash-completion
# user dir, so they are lazy-loaded on first <Tab> instead of costing
# startup time; regenerated when the binary is newer than the file.
# (install-linux-tools.sh also writes these, plus starship/delta.)
_bcd="${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion}/completions"
for _c in "uv generate-shell-completion bash" "uvx --generate-shell-completion bash" "gh completion -s bash"; do
	_b="${_c%% *}"
	_bin "$_b" || continue
	if [ ! -s "$_bcd/$_b" ] || [ "$REPLY" -nt "$_bcd/$_b" ]; then
		mkdir -p "$_bcd" && $_c > "$_bcd/$_b" 2> /dev/null
	fi
done
unset _bcd _c _b

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


# (guarded: /localscratch is per-host, and the hook costs a fork even when
# conda is absent)
if [ -x /localscratch/miniconda3/bin/conda ]; then
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
fi


# opencode
_path_prepend "$HOME/.opencode/bin"
# keep user-local binaries ahead of conda and everything else
_path_prepend "$HOME/.local/bin"
