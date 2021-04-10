# --== operating system (Darwin, Linux, etc.) ==--

export OS_NAME="$(uname)"
case "$OS_NAME" in
	Darwin)
		export IS_MACOSX=1
		;;
	Linux)
		export IS_LINUX=1
		;;
	CYGWIN*)
		export IS_WINDOWS=1
		;;
esac

# --== start ==--

# open a UI browser for the specified folder using 'start'
if [ "$IS_MACOSX" ]; then
	alias start='open'
elif [ "$IS_LINUX" ]; then
	alias start='nautilus'
elif [ "$IS_WINDOWS" ]; then
	alias start='cmd /c start'
fi

# --== sed ==--

# make in-place sed editing consistent across OSes
if [ "$IS_MACOSX" ]; then
	# BSD sed requires a space after -i argument
	alias sedi="sed -i ''"
else
	# GNU sed requires no space after -i argument
	alias sedi="sed -i''"
fi
