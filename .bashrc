#!/bin/bash

function joinStrings {
  local IFS="$1"
  shift
  echo "$*"
}
function prependOrBringToFrontOfArray() {
  local string=$1
  local newEntry=$2
  local delimiter=$3
  IFS="$delimiter" read -r -a array <<< "$string"

  for i in "${!array[@]}"; do
    if [[ "${array[$i]}" = "${newEntry}" ]]; then
      unset "array[$i]"
      break;
    fi
  done
  echo "$newEntry:$(joinStrings ':' ${array[@]})"
}

function sortOutPathEntries() {
  function prependToPath() {
    local newEntry=$1
    export PATH=$(prependOrBringToFrontOfArray $PATH $newEntry ':')
  }

  # Add gnu niceness. Probably on a mac if we have to do this
  if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
    prependToPath "/usr/local/opt/coreutils/libexec/gnubin"
  fi

  # add scripts in the dotfiles/bin, and any homedir/bin
  export DOT_FILES_DIR=$(readlink -f ~/.bash_profile | xargs dirname)
  prependToPath "$DOT_FILES_DIR/bin"
  prependToPath "~/bin"

  # add rvm scripts
  if [ -d $HOME/.rvm ]; then
    # Add RVM to PATH for scripting
    echo $PATH | grep -qv "$HOME/.rvm/bin" && export PATH="$PATH:$HOME/.rvm/bin"
  fi
}

function setUpAliases() {
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

  alias atomd='atom ~/dotfiles'
}

function setExports() {
  export MYSQL_PS1="\u@\h:\d \c> "
  # ensure EDITOR is set for git, shibboleth, whatever
  export EDITOR=vim

  # less syntax highlighting
  if [ -f /usr/local/bin/src-hilite-lesspipe.sh ]; then
    export LESSOPEN="| /usr/local/bin/src-hilite-lesspipe.sh %s"
    export LESS=' -R '
  fi
}

function initDockerMachineEnv() {
  if [[ $(command -v docker-machine) ]]; then
    eval "$(docker-machine env default)"
  fi
}

function loadCredentials() {
  # import credentials into environment
  if [ -d ~/.credentials ]; then
    for b in ~/.credentials/*; do
      . $b
    done
  fi
}

sortOutPathEntries
setUpAliases
setExports
initDockerMachineEnv
loadCredentials
