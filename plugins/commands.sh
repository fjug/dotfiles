# --== basics ==--

# Listing: eza if available, otherwise plain ls with the same muscle memory.
if command -v eza > /dev/null 2>&1; then
	alias ls='eza --group-directories-first'
	alias ll='eza -l --git --group-directories-first'
	alias la='eza -la --git --group-directories-first'
	alias lt='eza --tree --level=2'
elif [ "$IS_LINUX" ]; then
	alias ls='ls --color=auto'
	alias ll='ls -lh --color=auto'
	alias la='ls -lah --color=auto'
	alias lt='ls -laht --color=auto'
	export LS_COLORS="ow=30;42"
else
	# BSD ls (macOS): colour comes from CLICOLOR/LSCOLORS
	alias ll='ls -lh'
	alias la='ls -lah'
	alias lt='ls -laht'
fi
if [ "$IS_MACOSX" ]; then
	export LSCOLORS="ExGxBxDxCxEgedabagacad"
fi

# syntax-coloured cat when bat is installed ('batcat' on Debian/Ubuntu);
# 'catp' is the untouched original
if command -v bat > /dev/null 2>&1; then
	alias cat='bat --paging=never --style=plain'
	alias catp='command cat'
	export BAT_THEME="ansi"
elif command -v batcat > /dev/null 2>&1; then
	alias bat='batcat'
	alias cat='batcat --paging=never --style=plain'
	alias catp='command cat'
	export BAT_THEME="ansi"
fi
command -v btop > /dev/null 2>&1 && alias top='btop'
command -v lazygit > /dev/null 2>&1 && alias lg='lazygit'

# --== navigation ==--

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cdgit='cd ~/GIT'
alias d='dirs -v'
alias dotfiles='cd "$DOTFILES"'

# mkcd - make a directory and step into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# --== git ==--

# alias some common git typos
alias giot='git'
alias goit='git'
alias got='git'
alias gti='git'

# a handful of short git aliases (everything else is a git alias in gitconfig)
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

# git-latexdiff <file.tex> <n> - diff a .tex file against HEAD~n, open the PDF
git-latexdiff() {
	if [ $# -ne 2 ]; then
		echo "usage: git-latexdiff <file.tex> <back-revision>" >&2
		return 1
	fi
	if [ "$2" -lt 0 ] 2> /dev/null; then
		echo "git-latexdiff: <back-revision> must be positive" >&2
		return 1
	fi
	local dire based
	dire=$(dirname "$PWD/$1")
	based=$(git rev-parse --show-toplevel) || return 1
	git show "HEAD~$2:${dire#$based/}/$1" > "$1_diff.tmp" || return 1
	latexdiff "$1" "$1_diff.tmp" > "$1_diff.tex" || return 1
	pdflatex "$1_diff.tex"
	if [ "$IS_MACOSX" ]; then
		open "$1_diff.pdf"
	else
		${PDFVIEWER:-xdg-open} "$1_diff.pdf"
	fi
	rm -f "$1_diff.tmp" "$1_diff.tex" "$1_diff.aux" "$1_diff.log"
}

# --== myrepos ==--

alias mr='mr --stats'

# --== xterm ==--

alias xterm='xterm -geometry 80x60 -fg white -bg black'

# change the title of the current xterm
tt() {
	if [ "${SHELL##*/}" = "zsh" ]
	then
		if [ "$@" ]
		then
			# Disable automatic titles
			DISABLE_AUTO_TITLE="true"
			echo -ne "\e]1;$@\a"
		else
			# Switch back to automatic titles
			unset DISABLE_AUTO_TITLE
		fi
	else
		TERM_TITLE="$@"
	fi
}

# --== diff ==--

# use git for superior diff formatting
diff() { git diff --no-index $@; }

# --== vim ==--

alias vi='vim'

# viq - format the clipboard as an email quote
alias viq="vi \
	+'set tw=72' \
	+'normal! \"+p' \
	+':silent :1g/^$/d' \
	+':silent :g/^/s//> /' \
	+'normal! 1GVGgq1G\"+yG'"

# --== shell ==--

alias mv='mv -i'
# NB: To get clear on Cygwin, install ncurses.
alias cls='clear;pwd;ls'
alias cdiff='colordiff 2> /dev/null'
alias grep='grep --color=auto'
alias cgrep='grep --color=always'
alias rgrep='grep -IR --exclude="*\.svn*"'
alias f='find . -name'

# --== version reporting ==--

# report details of the OS using 'version'
version() {
	test -x "$(which sw_vers 2> /dev/null)" && sw_vers
	test -e /proc/version && cat /proc/version
	test -x "$(which lsb_release 2> /dev/null)" && lsb_release -a
	test -e /etc/redhat-release && cat /etc/redhat-release
	test -x "$(which ver 2> /dev/null)" && ver
}

# --== history ==--

alias histime='HISTTIMEFORMAT="%F %T " history'

# --== misc ==--

alias today='date "+%Y-%m-%d %H:%M (%A)"'

# extract - one command for every archive format
extract() {
	if [ ! -f "$1" ]; then
		echo "extract: no such file: $1" >&2
		return 1
	fi
	case "$1" in
		*.tar.bz2|*.tbz2) tar xjf "$1" ;;
		*.tar.gz|*.tgz)   tar xzf "$1" ;;
		*.tar.xz)         tar xJf "$1" ;;
		*.tar)            tar xf "$1" ;;
		*.bz2)            bunzip2 "$1" ;;
		*.gz)             gunzip "$1" ;;
		*.zip)            unzip "$1" ;;
		*.7z)             7z x "$1" ;;
		*.rar)            unrar x "$1" ;;
		*) echo "extract: don't know how to unpack $1" >&2; return 1 ;;
	esac
}

# --== eject ==--

if command -v diskutil > /dev/null 2>&1; then
  alias eject='diskutil eject'
fi

# --== ldd ==--

if ! command -v ldd > /dev/null 2>&1; then
	# make 'ldd' work on OS X
	alias ldd='otool -L'
fi

# --== hex editor ==--

# open a graphical hex editor using 'hex'
if command -v ghex2 > /dev/null 2>&1; then
	alias hex='ghex2'
elif [ -d '/Applications/Hex Fiend.app' ]; then
	alias hex="'/Applications/Hex Fiend.app/Contents/MacOS/Hex Fiend'"
fi

# --== tab removal ==--

# remove tabs from files using 'detab'
alias detab="sedi -e 's/	/  /g'"
