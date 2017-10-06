#!/bin/bash

export __DOTFILES_BASH_BASH_FUNCTIONS_LOADED="yes"

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

function srv() {
  if [[ "$#" != 1 ]]; then
    echo "Usage: srv <server>"
    echo "Echos a randomly chosen host:port from the SRV records for the server"
    return 1
  fi

  # server is the name in nslookup of the parameter
  local server=$1

  function doLookup() {
    nslookup -type=SRV $server \
      | grep --only-matching "\tservice = .*" \
      | cut -d " " -f 5,6 \
      | sed -r 's/([0-9]*) (.*)\./\2:\1/' \
      | shuf -n 1
  }

  local answer=$(doLookup)
  if [[ "$answer" == "" ]]; then
    # none found
    return 1
  else
    echo $answer
    return 0
  fi
}

# gets the current number of millis since the epoch.
# THIS DOESN'T WORK on normal mac. If it fails, check that gnubin is on the PATH
function current_time_millis() {
  echo $(($(date +%s%N)/1000000))
}

# converts milliseconds to a human-readable string
function convert_time_string() {
  local total_millis="$1"

  if [[ "${total_millis}" == "" ]]; then
    echo "Usage: convert_time_string <millis>"
    return 1
  fi

  ((total_secs=total_millis/1000))
  ((ms=total_millis%1000))
  ((s=total_secs%60))
  ((m=(total_secs%3600)/60))
  ((h=total_secs/3600))

  local time_string=""
  if   ((h>0)); then time_string="${h}h${m}m${s}s"
  elif ((m>0)); then time_string="${m}m${s}s"
  elif ((s>3)); then time_string="${s}s"
  elif ((s>0)); then time_string="${s}.$(printf "%0*d" 3 $ms | sed -e 's/[0]*$//g')s"
  else               time_string="${ms}ms"
  fi

  echo -n "${time_string}"

  # how do you do local vars on arithmetic?
  unset ms
  unset s
  unset m
  unset h
  unset total_secs
}

function sumLines() {
  paste -s -d+ | bc
}

function cassandraNetstatsSendingProgress() {
  nodetool netstats | awk '/Sending/ { soFar += $9; total += $2 }; END { print soFar * 100 / total "%" }'
}

function lsSockets() {
  local prefix=
  if [[ "$1" == -s ]]; then
    prefix="sudo"
  fi
  ${prefix} netstat -lntap | sed -e '2p' -e '/LISTEN/!d'
}

function ff() {
  local target=$1
  if [[ "$target" == "" ]]; then
    echo "Finds files with names containing the parameter"
    echo "Usage: $FUNCNAME <target-filename>"
    return 1;
  else
    if [[ $(command -v ag) ]]; then
      ag -g ".*${target}.*"
    elif [[ $(command -v ack) ]]; then
      ack -g ".*${target}.*"
    else
      find . -name "*${target}.*"
    fi
  fi
}

function chromeApp() {
  local url="$1"
  if [[ "$url" == "" ]]; then
    echo "Usage: chromeApp <url>"
    return 1
  fi

  local chrome='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

  "$chrome" --app="$url"
}

function sshl() {
  local startTime=$(current_time_millis)
  local -i sleeptime=5;
  if [[ -z $1 ]]; then
    echo 'usage: sshl <host> <command...>'
    return 1;
  fi;

  local ip=$1;
  shift;
  cmd=$@;
  while true; do
    ( ssh ${ip} 'uptime' > /dev/null 2>&1 ) && break;
    echo "$(date) - Not connected [${ip}]: sleeping ${sleeptime} seconds";
    sleep ${sleeptime};
  done;

  if [[ $(command -v terminal-notifier) ]]; then
    local endTime=$(current_time_millis)
    terminal-notifier -message "Connected to ${ip} after $(convert_time_string $(($endTime - $startTime)) )";
  fi
  ssh "${ip}" "${cmd}"
}

SCRATCHPAD_DIR=~/scratchpad
mkdir -p ${SCRATCHPAD_DIR}
# copy a file into the scratchpad directory
function scratch() {
  local files=("$@")

  if [ ${#files[@]} -eq 0 ]; then
    echo "Copies files into the scratchpad directory at [${GREEN}${SCRATCHPAD_DIR}${RESTORE}]"
    echo "Usage: scratch <filename ...>"
    return 1
  else
    for f in "${files[@]}"; do
      cp "$f" "${SCRATCHPAD_DIR}"
    done
  fi
}

function unslacked() {
  local channel=$1
  shift
  local message="$@"

  curl --data "channel=#${channel}&message=${message}&username=joe" http://unslacked/
}

function idea() {
  local ideaDir=$(find /Applications -maxdepth 1 -type d -name "IntelliJ*" | head -n 1)

  if [[ "$ideaDir" == "" ]]; then
    echo "Couldn't find an IntelliJ install directory"
    return 1
  fi

  local ideaApp="${ideaDir}/Contents/MacOS/idea"
  local project

  if [[ "$1" == "" ]]; then
    project="$(rlf .)"
  else
    project="$1"
  fi

  echo "Opening project at [${project}] with IntelliJ Idea from [${ideaApp}]"

  "${ideaApp}" "${project}"
}

function httpServe() {
  local directory=${1:-.}
  local port="8000"
  local bindHost="localhost"

  (cd $directory && echo "Serving directory [$(pwd)] on [http://${bindHost}:${port}]..." && python3 -m http.server ${port} --bind ${bindHost})
}

# Pulls a repo up to date, switches to that directory, and opens it in Atom
function cdga() {
  local repoIsh=$1
  cdgp $repoIsh && atom .
}
