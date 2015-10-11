# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

umask 027

# User specific aliases and functions
source ~/.bashrc

# git stuff
GIT_PS1_SHOWDIRTYSTATE=yes
GIT_PS1_SHOWSTASHSTATE=yes
GIT_PS1_SHOWUNTRACKEDFILES=yes
GIT_PS1_SHOWCOLORHINTS=yes
GIT_PS1_SHOWUPSTREAM="auto"
source ~/.git-prompt.sh

##################################################
# The home directory (HOME) is replaced with a ~
# The last pwdmaxlen characters of the PWD are displayed
# Leading partial directory names are striped off
# /home/me/stuff          -> ~/stuff               if USER=me
# /usr/share/big_dir_name -> .../share/big_dir_name if pwdmaxlen=20
##################################################
abbrev_pwd() {
    local lastExitStatus=$?

    # How many characters of the $PWD should be kept
    local pwdmaxlen=60
    # Indicate that there has been dir truncation
    local trunc_symbol="..."
    local dir=${PWD##*/}
    local pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
    local NEW_PWD=${PWD/#$HOME/\~}
    local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
    if [ ${pwdoffset} -gt "0" ]
    then
        NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
        NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
    fi

    # extra backslash before $ means it gets re-evaluated each time
    echo $NEW_PWD
}

# don't export this
# prompt courtesy of http://bashrcgenerator.com/
PROMPT_COMMAND='__git_ps1 "\[\033[38;5;14m\]\u\[$(tput sgr0)\]\[\033[38;5;8m\]@\[$(tput sgr0)\]\[\033[38;5;5m\]\h\[$(tput sgr0)\]\[\033[38;5;8m\]:\[$(tput sgr0)\]\[\033[38;5;14m\]\$(abbrev_pwd))\[$(tput sgr0)\]\[\033[38;5;15m\]" "\n\[$(tput sgr0)\]\[\033[38;5;10m\]\t\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\](\[$(tput sgr0)\]\[\033[38;5;9m\]\$?\[$(tput sgr0)\]\[\033[38;5;7m\])\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;7m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
