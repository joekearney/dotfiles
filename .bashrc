#!/bin/bash

alias ls='ls -G --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

export LESSOPEN="| /usr/local/bin/src-hilite-lesspipe.sh %s"
export LESS=' -R '

export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

eval $(boot2docker shellinit 2>/dev/null)
