#!/bin/bash

if [[ "$DOT_FILES_DIR" == "" ]]; then
  echo "${RED}DOT_FILES_DIR has not been defined for $0${RESTORE}"
fi

function runCommand() {
  if [[ "${ECHO_ONLY}" == "true" ]]; then
    echo "    [runCommand] $@"
  else
    "$@"
  fi
}
# Pushes the dotfiles directory to the target machine and links them
function pushDotFilesTo() {
  if [[ "$1" == "" ]]; then
    echo "Usage: pushDotFilesTo <host>"
  else
    local host=$1
    ${DOT_FILES_DIR}/pushDotFiles.sh $host
  fi
}
function pushDotFilesAndSshTo() {
  pushDotFilesTo $1 && ash $1
}

# Sources .bash_profile into the current environment
function reloadDotFiles() {
  . ~/.bash_profile
}

# sleeps for a number of seconds, displaying the number of seconds remaining.
function countdown() {
  local remaining=$1
  while ((remaining>0)); do
    echo $remaining
    sleep 1
    ((remaining=remaining-1))
  done
}

# sets the shell title
function shellTitle() {
    echo -ne "\033]0;"$*"\007"
}

# head and grep
function hag() {
  sed -e '1p' -e "/$1/!d"
}

export KNOWN_HOSTS_FILE=$DOT_FILES_DIR/.known_hosts
# ssh, but passing an LC environment variable with the expected target host name.
# This is so that you can ssh to some alias, that lands you on some target
# machine of a cluster, and be able to find out later what you though the host
# was called.
#
# If there are more arguments then we just delegate to the default ssh, and
# don't get the hostname passed through.
function ash() {
  if [[ "$1" == "" ]]; then
    # delegate to the error that ssh gives with no args
    ssh
  else
    local target_host=$1
    local shortname=$(echo $target_host | sed -e 's/\..*^//')
    grep -qFx "$target_host" $KNOWN_HOSTS_FILE || echo $target_host >> $KNOWN_HOSTS_FILE
    LC_alias_of_target_host=$shortname ssh $target_host
  fi
}
# bash auto completion for host names
function _ash_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  local lines
  IFS=$'\n' read -d '' -r -a lines < $KNOWN_HOSTS_FILE
  COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
}
complete -F _ash_complete_options ash

# Gets the hostname entered when ssh-ing to the machine.
function getExpectedHostname() {
  if [ ! -z "$LC_alias_of_target_host" ]; then
    echo "$LC_alias_of_target_host"
  else
    hostname -s
  fi
}
# Gets the hostname entered when ssh-ing to the machine.
function getExpectedHostnameAndOriginal() {
  if [ ! -z "$LC_alias_of_target_host" ]; then
    echo "$LC_alias_of_target_host = $(hostname -s)"
  else
    hostname -s
  fi
}

# indents stdout by two spaces, prefixed by the argument
function indent() {
  local prefix=$1
  sed "s/^/$1  /"
}

# let cd also pushd directories into stack. Use popd to reverse stack
function cd() {
  local target="$@"

  if [[ "$target" == "" ]]; then
    pushd ~ &> /dev/null
  elif [[ "$target" == "-" ]]; then
    popd &> /dev/null
  elif [[ "$target" == "?" ]]; then
    dirs -v | indent
    read -p "Enter index to jump to, or <enter> to do nothing: " i
    if [[ "$i" != "" ]]; then
      target=$(dirs +$i)
      if [[ "$?" == "0" ]]; then
        colorize "Jumping to [<light-green>$target</light-green>]"
        # need eval to handle ~ in target path
        eval cd "$target"
      fi
    fi
  elif [ -d "$target" ]; then
    pushd "$target" &> /dev/null   #dont display current stack
  else
    echo "No such directory: [$target]"
    return 1
  fi
}

# pipe from http to less, for a given URL
function httpless() {
  # --print=hb means print response headers and response body.
  http --pretty=all --print=hb "$@" | less
}

function docker-reset-hard() {
  docker-machine restart default && \
  eval "$(docker-machine env default)" && \
  yes | docker-machine regenerate-certs default
}

function weather() {
  http --body "wttr.in/$1"
}

# I can never remember which way round symlinks go
function mkLink() {
  echo "This will create a symlink from <name> -> <actual-file>."
  local target
  local name
  read -p "  Enter actual file:  " target
  read -p "  Enter name of link: " name

  echo "Creating symlink $name -> $target"

  ln -s $target $name
}

function runOn() {
  usage="Usage: $0 <host> [-b] <command...>"

  target=$1
  if [[ "$target" == "" ]]; then
    echo usage
    return 1
  fi

  shift 1

  background=no
  if [[ "$1" == "-b" ]]; then
    background=yes
    shift 1
  fi

  remoteCommands="$*"

  echo -n "Running: [$remoteCommands] on [$target]"
  if [[ "$background" == "yes" ]]; then
    echo " in the background..."
    ssh -A $target nohup $remoteCommands > /dev/null 2> /dev/null < /dev/null &
  else
    echo "..."
    ssh -A $target $remoteCommands
  fi
}

function rlf() {
  if [[ "$#" != 1 ]]; then
    echo "Usage: rlf <path>"
    echo "Finds the real path of the item given"
    return 1
  fi

  local thing=$1
  local whichThing=$(which $thing)

  if [[ "$whichThing" != "" ]]; then
    readlink -f $whichThing
  elif [[ -a "$thing" ]]; then
    readlink -f $thing
  else
    echo "[$thing] not found"
  fi
}
