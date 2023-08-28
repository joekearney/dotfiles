#!/bin/bash

# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bashrc.pre.bash" ]] && builtin source "$HOME/.fig/shell/bashrc.pre.bash"

function echoErr() {
  cat <<< "$@" 1>&2
}
function echoDebug() {
  if [[ "$DEBUG" == "yes" ]]; then
    echoErr "$@"
  fi
}

if (( "${BASH_VERSION:0:1}" < "4" )); then
  echoDebug "Requires Bash version >= 4, but found version [${BASH_VERSION}]."
  echoDebug "Things might go wrong, but carrying on regardless 🤞"
fi

# add scripts in the dotfiles/bin, and any homedir/bin
export DOT_FILES_DIR="$HOME/dotfiles"
echoDebug "Set dotfiles dir to $DOT_FILES_DIR"

# function to get the current number of millis since the epoch.
# THIS DOESN'T WORK on normal mac. This bit of magic makes the function round
# to seconds where necessary.
if command -v gdate >/dev/null; then
  function current_time_millis() {
    echo $(($(gdate +%s%N)/1000000))
  }
else
  DISABLE_NANOS=$(date +%s%N | grep -q 'N' && echo "yes" || echo "no")
  if [[ "${DISABLE_NANOS}" == "yes" ]]; then
    echoDebug "The [date] command does not support nanosecond-precision timing. Falling back to second-precision."
    function current_time_millis() {
      date +%s000
    }
  else
    function current_time_millis() {
      echo $(($(date +%s%N)/1000000))
    }
  fi
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
  echo "$newEntry:$(joinStrings ':' ${array[*]})"
}

function prependToPath() {
  local newEntry=$1
  if [[ "$newEntry" = *" "* ]]; then
    echoErr "PATH entries must not contain spaces: [$newEntry]. This entry will not be added."
  else
    export PATH=$(prependOrBringToFrontOfArray $PATH $newEntry ':')
  fi
}

function sortOutPathEntries() {

  # Add gnu niceness. Probably on a mac if we have to do this
  if [ -d /usr/local/opt/coreutils/libexec/gnubin ]; then
    prependToPath "/usr/local/opt/coreutils/libexec/gnubin"
  fi

  if [ -d ~/programs/google-cloud-sdk/bin ]; then
    prependToPath "$HOME/programs/google-cloud-sdk/bin"
  fi

  prependToPath "$DOT_FILES_DIR/bin"
  prependToPath "$HOME/bin"

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
  # prependToPath "$HOME/homebrew/bin"
  # export LD_LIBRARY_PATH=$HOME/homebrew/lib:$LD_LIBRARY_PATH

  if [ -d /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  prependToPath "/snap/bin"
  prependToPath "$HOME/.local/bin"

  prependToPath "/usr/local/bin"
  prependToPath "$HOME/bin"
}

export DOTFILE_EDITOR_DIRS="$HOME/dotfiles $HOME/bin $HOME/.ssh $HOME/.machine-specific.bash"

function setUpAliases() {
  alias ls='ls --color=auto'
  alias ll='ls -lh'
  alias la='ls -lAh'

  # alias dir='dir --color=auto'
  # alias vdir='vdir --color=auto'
  #
  # alias grep='grep --color=auto'
  # alias fgrep='fgrep --color=auto'
  # alias egrep='egrep --color=auto'
  #
  # alias rud='rvm use default'

  alias atomd="atom \$DOTFILE_EDITOR_DIRS"
  alias coded="code \$DOTFILE_EDITOR_DIRS"
  alias tn='network-test.sh'

  alias clearDnsCache="sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder;say flushed"

  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

  if [ -f ~/.iterm2/imgcat ]; then
    alias imgcat=~/.iterm2/imgcat
  fi
}

function setExports() {
  # pretty colours for `ls` even when it doesn't support --color=auto
  export CLICOLOR=xterm-color

  # ensure EDITOR is set for git, shibboleth, whatever
  export EDITOR=vim

  # less syntax highlighting
  if [ -f /usr/local/bin/src-hilite-lesspipe.sh ]; then
    export LESSOPEN="| /usr/local/bin/src-hilite-lesspipe.sh %s"
    export LESS=' -R '
  fi

  export LC_ALL=en_GB.UTF-8
  export LANG=en_GB.UTF-8
  export LANGUAGE=en_GB.UTF-8

  # Suppressing "The default interactive shell is now zsh" message in macOS Catalina
  export BASH_SILENCE_DEPRECATION_WARNING=1

  # Don't uninstall old bash versions. If a new version is broken, this means no shell.
  export HOMEBREW_NO_CLEANUP_FORMULAE=bash
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
  if [[ "$f" != "" && -f $f ]]; then
    echoDebug "Sourcing file $f..."
    startTimer
    . $f
    endTimer ". $f"
    echoDebug "Sourced file $f"
  else
    echoDebug "No file $f found for sourcing"
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

  umask 022
}

sortOutPathEntries
setUpAliases
setExports
sensibleBashDefaults

# Source global definitions
loadIfExists /etc/bashrc

# load colours
loadIfExists "$DOT_FILES_DIR/colour/.bash_color_vars"

# Load RVM into a shell session *as a function*
# if file exists and is non-empty
loadIfExists "$HOME/.rvm/scripts/rvm"

# load functions
for thing in bash git sbt; do
  loadIfExists "${DOT_FILES_DIR}/$thing/$thing-functions.sh"
done

# load bash_completions from various sources
# the standard ones -- this seems to break prompt on some hosts
if [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Source machine-local environment
loadIfExists "$HOME/.machine-specific.bash"
loadIfExists "$HOME/.local_env.sh"

# load brew-installed completions if they exist
# this is really expensive
if [[ $(command -v brew) && -f $(brew --prefix)/etc/bash_completion ]]; then
  BREW_PREFIX="$(brew --prefix)"
  loadIfExists "$BREW_PREFIX/etc/bash_completion"
  loadIfExists "$BREW_PREFIX/etc/profile.d/bash_completion.sh"
fi

# load custom bash completion scripts
if [ -d ${DOT_FILES_DIR}/bash_completion ]; then
  for b in ${DOT_FILES_DIR}/bash_completion/*; do
    loadIfExists "$b"
  done
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
loadIfExists "$SDKMAN_DIR/bin/sdkman-init.sh"

# load custom prompt
loadIfExists "${DOT_FILES_DIR}/bash/bash_prompt.sh"

loadIfExists "$HOME/.cargo/env"

loadCredentials

FINISHED_LOADING_BASH_RC=current_time_millis
echoDebug "Loading bash took $((FINISHED_LOADING_BASH_RC-STARTED_LOADING_BASH_RC))ms"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bashrc.post.bash" ]] && builtin source "$HOME/.fig/shell/bashrc.post.bash"
