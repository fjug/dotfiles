# --- core zsh behaviour ------------------------------------------------------

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY        # record timestamps
setopt INC_APPEND_HISTORY      # write as you go, not only on exit
setopt SHARE_HISTORY           # share across running shells
setopt HIST_IGNORE_ALL_DUPS    # keep only the most recent copy of a command
setopt HIST_IGNORE_SPACE       # a leading space keeps it out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY             # expand !! but let me confirm before running

# Directories — replaces the oh-my-zsh `dirpersist` plugin
setopt AUTO_CD                 # `..` and bare paths just cd
setopt AUTO_PUSHD              # every cd pushes onto the stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
DIRSTACKSIZE=20

# Globbing and misc
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB
setopt INTERACTIVE_COMMENTS    # allow `# comments` at the prompt
setopt NO_BEEP
unsetopt FLOW_CONTROL          # free up ^S / ^Q

# Colours in ls and friends
export CLICOLOR=1
export LSCOLORS=dxfxcxdxbxegedabagacad
export LS_COLORS='di=33:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# Coloured man pages — replaces the oh-my-zsh `colored-man-pages` plugin
man() {
  LESS_TERMCAP_md=$'\e[1;34m' \
  LESS_TERMCAP_me=$'\e[0m' \
  LESS_TERMCAP_us=$'\e[4;32m' \
  LESS_TERMCAP_ue=$'\e[0m' \
  LESS_TERMCAP_so=$'\e[1;33;44m' \
  LESS_TERMCAP_se=$'\e[0m' \
  command man "$@"
}
