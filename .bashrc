#!/bin/bash

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

function sortOutPathEntries() {
  function prependToPath() {
    local newEntry=$1
    if echo $PATH | grep -qv $newEntry; then
      export PATH="$newEntry:$PATH"
    fi
  }

  # Add gnu niceness. Probably on a mac if we have to do this
  if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
    prependToPath "/usr/local/opt/coreutils/libexec/gnubin"
  fi

  # add scripts in the dotfiles/bin, and any homedir/bin
  DOT_FILES_DIR=$(readlink -f ~/.bash_profile | xargs dirname)
  prependToPath "$DOT_FILES_DIR/bin"
  prependToPath "~/bin"

  # add rvm scripts. These always want to be on the front of the path
  if [ -d $HOME/.rvm ]; then
    # Add RVM to PATH for scripting
    prependToPath "$HOME/.rvm/bin"
  fi
}

function initDockerMachineEnv() {
  if [[ $(command -v docker-machine) ]]; then
    docker-machine status default | grep -q Running
    statusExitCode=$?
    if [[ $statusExitCode == '0' ]]; then
      eval "$(docker-machine env default)"
    else
      echo "docker-machine default is not running. If you want the environment set up, run:"
      echo ""
      echo '    docker-machine start default && eval $(docker-machine env default)'
      echo ""
    fi
    unset statusExitCode
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

setUpAliases
setExports
sortOutPathEntries
initDockerMachineEnv
loadCredentials
