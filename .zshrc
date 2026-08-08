# Path to your oh-my-zsh installation.
export ZSH=~/.dotfiles/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="robbyrussell"
ZSH_THEME="bira_conda"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Add wisely, as too many plugins slow down shell startup.
zstyle :omz:plugins:ssh-agent identities ht id_rsa
zstyle :omz:plugins:ssh-agent agent-forwarding on
plugins=(z ssh-agent git brew history history-substring-search colored-man-pages colorize cp dirpersist vi-mode vundle gradle mercurial mvn pip python macos textmate themes)

# User configuration

export PATH="/Users/florian.jug/bin:/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/3.0.0/bin:$PATH"

source $ZSH/oh-my-zsh.sh

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="mate ~/.zshrc"
alias ohmyzsh="mate ~/.oh-my-zsh"
alias mrbranches="mr run git branch | grep '^mr\|^*' | sed s/mr\ run:\ //"
alias mvndoc='mvn javadoc:javadoc > javadocoutput.txt | grep ": error"'
alias safari='open -a Safari'
alias safari2='open -n -a /Applications/SafariInstance2.app'
alias deNBI='ssh -p 30253 -i ~/.ssh/ht ubuntu@129.70.51.6'
alias deNBI8888='ssh -p 30253 -i ~/.ssh/ht ubuntu@129.70.51.6 -L 8888:localhost:8888'
alias scpdeNBI='scp -i ht -P 30253'

# The Fuck
eval $(thefuck --alias)
# Please
alias please='sudo $(fc -ln -1) && echo "Okay..."'

# Convenient history searched reverse and forward
bindkey "^R" history-incremental-pattern-search-backward
bindkey "^S" history-incremental-pattern-search-forward

# CONDA
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/florian.jug/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/florian.jug/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/florian.jug/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/florian.jug/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# turn off the PROMPT changes conda does per default (our zsh theme does it)
conda config --set changeps1 false

# LaTeX-diff
function git-latexdiff {    
    if [[ $# != 2 ]];    
    then      
        printf "\tusage: git-latexdiff <file> <back-revision>  \n";    
    elif [[ $2 -lt 0 ]];     
    then     
        printf "\t<Back-revision> must be positive\n";   
    else      
        dire=$(dirname $PWD/$1);      
        based=$(git rev-parse --show-toplevel);      
        git show HEAD~$2:$(echo $dire| sed 's!'$(echo $based)'/!!')/$1 > $1_diff.tmp;      
        latexdiff $1 $1_diff.tmp > $1_diff.tex;      
        pdflatex $1_diff.tex;     
        okular $1_diff.pdf;      
        rm $1_diff*;   
    fi; 
}

# Homebrew related
export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"

# Gurobi
export PATH="/Library/gurobi951/macos_universal2/bin:$PATH"


export PATH="$HOME/reMarkable/bin:$PATH"
export PATH="$HOME/Kobo/bin:$PATH"
