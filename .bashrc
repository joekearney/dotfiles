#!/bin/bash

DEBUG=no
if [[ "$DEBUG" == "yes" ]]; then
  set -x
fi

function echoErr() {
  cat <<< "$@" 1>&2
}
function echoDebug() {
  if [[ "$DEBUG" == "yes" ]]; then
    echoErr "$@"
  fi
}

EXIT_WITHOUT_BASH_4=no

if (( "${BASH_VERSION:0:1}" < "4" )); then
  echoErr "Requires Bash version >= 4, but found version [${BASH_VERSION}]."

  if [[ "${EXIT_WITHOUT_BASH_4}" == "yes" ]]; then
    echoErr "Exiting in 10 seconds..."
    sleep 10
    exit
  else
    echoErr "Things might go wrong, but carrying on regardless 🤞"
  fi
fi

# function to get the current number of millis since the epoch.
# THIS DOESN'T WORK on normal mac. This bit of magic makes the function round
# to seconds where necessary.
DISABLE_NANOS=$(date +%s%N | grep -q 'N' && echo "yes" || echo "no")
if [[ "${DISABLE_NANOS}" == "yes" ]]; then
  echoErr "The [date] command does not support nanosecond-precision timing"
  function current_time_millis() {
    date +%s000
  }
else
  function current_time_millis() {
    echo $(($(date +%s%N)/1000000))
  }
fi

STARTED_LOADING_BASH_RC=current_time_millis

if [[ "$DEBUG" == "yes" ]]; then
  function startTimer() {
    TIMER_START=$(current_time_millis)
  }
  function endTimer() {
    local end=$(current_time_millis)
    local elapsed=$((end-TIMER_START))
    unset TIMER_START
    local name=$1
    echo "Running [$name] took ${elapsed}ms"
  }
else
  function startTimer() {
    true
  }
  function endTimer() {
    true
  }
fi

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

  if [ -d ~/programs/google-cloud-sdk/bin ]; then
    prependToPath "~/programs/google-cloud-sdk/bin"
  fi

  # add scripts in the dotfiles/bin, and any homedir/bin
  export DOT_FILES_DIR=$(cd ~/dotfiles && pwd)
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

  # homebrew
  prependToPath "$HOME/homebrew/bin"
  export LD_LIBRARY_PATH=$HOME/homebrew/lib:$LD_LIBRARY_PATH

  prependToPath "/usr/local/bin"
  prependToPath "$HOME/bin"
}

function setUpAliases() {
  #alias ls='ls -G --color=auto'
  alias ll='ls -lh'
  alias la='ls -lAh'
  alias ld='ls -lAdh .*'

  alias cb='popd'
  alias cdd='cd ~/dotfiles'
  alias cds='cd ~/scratchpad'

  alias dir='dir --color=auto'
  alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'

  alias rud='rvm use default'

  alias atomd='atom ~/dotfiles ~/.ssh ~'
  alias atoms='atom ~/scratchpad'
  alias tn='network-test.sh'

  alias clearDnsCache="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder;say flushed"

  if [ -f ~/.iterm2/imgcat ]; then
    alias imgcat=~/.iterm2/imgcat
  fi
}

function setExports() {
  export LANG=en_GB.UTF-8

  # pretty colours for `ls` even when it doesn't support --color=auto
  export CLICOLOR=xterm-color

  export MYSQL_PS1="\u@\h:\d \c> "
  # ensure EDITOR is set for git, shibboleth, whatever
  export EDITOR=vim

  # less syntax highlighting
  if [ -f /usr/local/bin/src-hilite-lesspipe.sh ]; then
    export LESSOPEN="| /usr/local/bin/src-hilite-lesspipe.sh %s"
    export LESS=' -R '
  fi

  if command -v /usr/libexec/java_home > /dev/null && /usr/libexec/java_home -v 1.8 2&>1 > /dev/null; then
    export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
  fi

  export LC_ALL=en_GB.UTF-8
  export LANG=en_GB.UTF-8
  export LANGUAGE=en_GB.UTF-8

  export GOPATH=~/git
}

function loadCredentials() {
  # import credentials into environment
  if [ -d ~/.credentials ]; then
    for b in ~/.credentials/*; do
      . $b
    done
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
    keyPath=~/.ssh/id_rsa

    if [ -f ${keyPath} ]; then
      # check whether the identity is already in the agent
      ssh-add -L | grep -qv ${keyPath}

      # if not, add it to the agent
      if [[ "$?" == "0" ]]; then
        ssh-add -q ${keyPath}
      fi
    fi
  fi
}
function loadIfExists() {
  local f=$1
  if [ -f $f ]; then
    echoDebug "Sourcing file $f..."
    startTimer
    . $f
    endTimer ". $f"
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
#  bind "TAB:menu-complete"
#  bind "set show-all-if-ambiguous on"

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
function rvmLoad() {
  loadIfExists "$HOME/.rvm/scripts/rvm"
}

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
# this is really expensive
if [[ $(command -v brew) && -f $(brew --prefix)/etc/bash_completion ]]; then
  echoDebug "Loading bash_completion file for brew"
  startTimer
  . $(brew --prefix)/etc/bash_completion
  endTimer "load brew bash completions"
fi
# any custom ones
if [ -d ${DOT_FILES_DIR}/bash_completion ]; then
  for b in ${DOT_FILES_DIR}/bash_completion/*; do
    startTimer
    echoDebug "Loading bash_completion file [$b]"
    . $b
    endTimer "load bash completions from $b"
  done
fi

loadIfExists "~/programs/google-cloud-sdk/path.bash.inc"
loadIfExists "~/programs/google-cloud-sdk/completion.bash.inc"

if which aws_completer > /dev/null 2>&1; then
  complete -C "$(which aws_completer)" aws
fi

loadIfExists "~/bin/local_completions.bash"

# load custom prompt
if [ -f ${DOT_FILES_DIR}/bash/bash_prompt.sh ]; then
  echoDebug "Loading bash prompt definition..."
  . ${DOT_FILES_DIR}/bash/bash_prompt.sh
fi

loadCredentials

FINISHED_LOADING_BASH_RC=current_time_millis
echoDebug "Loading bash took $((FINISHED_LOADING_BASH_RC-STARTED_LOADING_BASH_RC))ms"
