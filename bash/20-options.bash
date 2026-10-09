# --- core bash behaviour -----------------------------------------------------
# Each setting notes the zsh option it mirrors, so the two shells stay in step.

# History
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups   # HIST_IGNORE_ALL_DUPS + HIST_IGNORE_SPACE
export HISTTIMEFORMAT='%F %T '            # EXTENDED_HISTORY
shopt -s histappend checkwinsize cdspell 2> /dev/null
shopt -s histverify                       # HIST_VERIFY: show !! before running it
shopt -s autocd                           # AUTO_CD: a bare directory name cd's
shopt -s extglob nocaseglob               # EXTENDED_GLOB, NO_CASE_GLOB
shopt -s globstar 2> /dev/null            # ** (bash 4+; absent in macOS bash 3.2)
shopt -s dirspell 2> /dev/null

# INC_APPEND_HISTORY: write each command as it runs rather than at exit, so a
# second terminal sees it immediately. Prepended, so starship's own
# PROMPT_COMMAND (set later) is kept.
case ";$PROMPT_COMMAND;" in
  *"history -a"*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# unsetopt FLOW_CONTROL: free up ^S / ^Q for history search
[ -t 0 ] && stty -ixon 2> /dev/null

# vi editing mode, as in zsh (bindkey -v). ~/.inputrc keeps the emacs movement
# keys in insert mode and switches the cursor shape per mode.
set -o vi

# Coloured man pages — replaces the oh-my-zsh colored-man-pages plugin.
man() {
  LESS_TERMCAP_md=$'\e[1;34m' \
  LESS_TERMCAP_me=$'\e[0m' \
  LESS_TERMCAP_us=$'\e[4;32m' \
  LESS_TERMCAP_ue=$'\e[0m' \
  LESS_TERMCAP_so=$'\e[1;33;44m' \
  LESS_TERMCAP_se=$'\e[0m' \
  command man "$@"
}
