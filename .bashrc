#!/bin/bash

DEBUG=no
function echoDebug() {
  if [[ "$DEBUG" == "yes" ]]; then
    echo "$@"
  fi
}

echoDebug "In .bashrc"

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
  echoDebug "Set dotfiles dir to $DOT_FILES_DIR"
  prependToPath "$DOT_FILES_DIR/bin"
  prependToPath "~/bin"

  # added Miniconda2 3.19.0 to head of path
  if [[ -s "$HOME/.miniconda2" ]]; then
    prependToPath "/Users/joekearney/.miniconda2/bin"
  fi

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

  alias rud='rvm use default'

  alias atomd='atom ~/dotfiles'
  alias tn='network-test.sh'

  if [ -f ~/.iterm2/imgcat ]; then
    alias imgcat=~/.iterm2/imgcat
  fi
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

  # export LC_ALL=en_GB.UTF-8
  # export LANG=en_GB.UTF-8
  # export LANGUAGE=en_GB.UTF-8
}

function initDockerMachineEnv() {
  if [[ $(command -v docker-machine > /dev/null && docker-machine status) == "Running" ]]; then
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
function loadIfExists() {
  local f=$1
  echoDebug "Sourcing file $f..."
  if [ -f $f ]; then
    . $f
    echoDebug "Sourced file $f"
  fi
}
function sensibleBashDefaults() {
  # from https://github.com/mrzool/bash-sensible/blob/master/sensible.bash

  # Prevent file overwrite on stdout redirection
#  set -o noclobber

  # Update window size after every command
  shopt -s checkwinsize

  # # Perform file completion in a case insensitive fashion
  # bind "set completion-ignore-case on"
  #
  # # Treat hyphens and underscores as equivalent
  # bind "set completion-map-case on"

  # Display matches for ambiguous patterns at first tab press
  bind "TAB:menu-complete"
  bind "set show-all-if-ambiguous on"

  # Append to the history file, don't overwrite it
  shopt -s histappend

  # Save multi-line commands as one command
  shopt -s cmdhist

  # Huge history. Doesn't appear to slow things down, so why not?
  HISTSIZE=500000
  HISTFILESIZE=100000

  # Avoid duplicate entries
  HISTCONTROL="erasedups:ignoreboth"

  # Don't record some commands
  export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"

  # Useful timestamp format
  HISTTIMEFORMAT='%F %T '
}

sortOutPathEntries
setUpAliases
setExports
sensibleBashDefaults

# this is a safe and sensible umask
umask 027

# Source global definitions
loadIfExists /etc/bashrc

# Source machine-local environment
loadIfExists ~/.local_env.sh

# load colours
loadIfExists $DOT_FILES_DIR/colour/.bash_color_vars

# Load RVM into a shell session *as a function*
# if file exists and is non-empty
loadIfExists "$HOME/.rvm/scripts/rvm"

# load functions
for thing in bash git sbt tunnelblick; do
  loadIfExists ${DOT_FILES_DIR}/$thing/$thing-functions.sh
done

# load bash_completions from various sources
# the standard ones -- this seems to break prompt on some hosts
#if [ -f /etc/bash_completion ]; then
#  . /etc/bash_completion
#fi
# from brew-installed sources if they exist
if [[ $(command -v brew) && -f $(brew --prefix)/etc/bash_completion ]]; then
  . $(brew --prefix)/etc/bash_completion
fi
# any custom ones
if [ -d ${DOT_FILES_DIR}/bash_completion ]; then
  for b in ${DOT_FILES_DIR}/bash_completion/*; do
    . $b
  done
fi

# load custom prompt
if [ -f ${DOT_FILES_DIR}/bash/bash_prompt.sh ]; then
  . ${DOT_FILES_DIR}/bash/bash_prompt.sh
fi

initDockerMachineEnv
loadCredentials
