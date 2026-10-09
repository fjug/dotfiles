# Legacy conda location; only used if it exists (the VDI's conda lives in
# /localscratch/miniconda3 and is initialised at the end of bashrc).
if [ -x "$HOME/miniconda3/bin/conda" ]; then
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/florian.jug/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/florian.jug/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/florian.jug/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/florian.jug/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
fi
