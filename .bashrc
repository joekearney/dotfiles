#!/bin/bash

alias ls='ls -G --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias ld='ls -lAdh .*'

alias cb='popd'
alias cdd='cd ~/dotfiles'

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

export MYSQL_PS1="\u@\h:\d \c> "
# ensure EDITOR is set for git, shibboleth, whatever
export EDITOR=vim

if [ -f /usr/local/bin/src-hilite-lesspipe.sh ]; then
  export LESSOPEN="| /usr/local/bin/src-hilite-lesspipe.sh %s"
  export LESS=' -R '
fi

if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
  # Add gnu niceness, probably on a mac at this point
  export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
fi
if [ -d $HOME/.rvm ]; then
  # Add RVM to PATH for scripting
  export PATH="$PATH:$HOME/.rvm/bin"
fi

DOT_FILES_DIR=$(readlink -f ~/.bash_profile | xargs dirname)
export PATH="~/bin:$DOT_FILES_DIR/bin:$PATH"

if [[ $(command -v boot2docker) ]]; then
  eval $(boot2docker shellinit 2>/dev/null)
fi

# import credentials into environment
if [ -d ~/.credentials ]; then
  for b in ~/.credentials/*; do
    . $b
  done
fi
