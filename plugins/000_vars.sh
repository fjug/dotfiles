# use vim to edit commit messages
export EDITOR=vim
export VISUAL="$EDITOR"
export PAGER=less

# --== Homebrew ==--

# (bashrc already sets BREW on macOS; avoid the slow 'brew --prefix' call)
if [ -z "$BREW" ] && [ -n "$HOMEBREW_PREFIX" ]; then
	export BREW="$HOMEBREW_PREFIX"
fi

# --== CVS ==--

export CVS_RSH=ssh

# --== SVN ==--

# do not autocomplete .svn folders
export FIGNORE=.svn

# --== Python sphinx ==--

# fail the sphinx build when there are warnings
export SPHINXOPTS=-W

# --== less ==--

# raw colours, quit if one screen, don't clear the screen on exit
export LESS='-R -F -X'
# enable syntax highlighting in less
if [ -d /usr/share/source-highlight ]; then
	export LESSOPEN="| /usr/share/source-highlight/src-hilite-lesspipe.sh %s"
elif [ -d $HOME/brew/Cellar/source-highlight ]; then
	export LESSOPEN="| $HOME/brew/Cellar/source-highlight/*/bin/src-hilite-lesspipe.sh %s"
fi

# --== xmllint ==--

# indent XML with tabs
export XMLLINT_INDENT=$'\t'
