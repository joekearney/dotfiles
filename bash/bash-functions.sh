#!/bin/bash

export __DOTFILES_BASH_BASH_FUNCTIONS_LOADED="yes"

function echoErr() {
  cat <<< "$@" 1>&2
}

if [[ "$DOT_FILES_DIR" == "" ]]; then
  echoErr "${RED}DOT_FILES_DIR has not been defined for $0${RESTORE}"
fi

function runCommand() {
  if [[ "${ECHO_ONLY:-false}" == "true" ]]; then
    echoErr "    [runCommand] $*"
  else
    echoErr "    [runCommand] $*"
    "$@"
  fi
}
# Pushes the dotfiles directory to the target machine and links them
function pushDotFilesTo() {
  if [[ "$1" == "" ]]; then
    echoErr "Usage: pushDotFilesTo <host>"
  else
    local host=$1
    if ! type rc-files-to-push &> /dev/null; then
      "${DOT_FILES_DIR}/pushDotFiles.sh" "$host"
    else
      rc-files-to-push | xargs "${DOT_FILES_DIR}/pushDotFiles.sh" "$host"
    fi
  fi
}
function pushDotFilesAndSshTo() {
  pushDotFilesTo "$1" && ssh "$1"
}

# Sources .bash_profile into the current environment
function reloadDotFiles() {
  . ~/.bash_profile
}

# sets the shell title
function shellTitle() {
    echo -ne "\033]0;"$*"\007"
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
    echoErr "No such directory: [$target]"
    return 1
  fi
}

# I can never remember which way round symlinks go
function mkLink() {
  echoErr "This will create a symlink from <name> -> <actual-file>."
  local target
  local name
  read -p "  Enter actual file:  " target
  read -p "  Enter name of link: " name

  echo "Creating symlink $name -> $target"

  ln -s $target $name
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
  if   ((h>0)); then
    time_string="${h}h${m}m${s}s"
  elif ((m>0)); then
    time_string="${m}m${s}s"
  elif ((s>3)); then
    time_string="${s}s"
  elif ((s>0)); then
    # sort out trailing 0s after the decimal
    time_string="$(printf "%d.%0*d" ${s} 3 ${ms} | sed '/\./ s/\.\{0,1\}0\{1,\}$//')s"
  elif ((ms==0)); then
    time_string="0s"
  else
    time_string="${ms}ms"
  fi

  echo "${time_string}"

  # how do you do local vars on arithmetic?
  unset ms
  unset s
  unset m
  unset h
  unset total_secs
}

function lsSockets() {
  local prefix=
  if [[ "$1" == -s ]]; then
    prefix="sudo"
  fi
  ${prefix} netstat -lntap | sed -e '2p' -e '/LISTEN/!d'
}

function sshl() {
  local startTime=$(current_time_millis)
  local -i sleeptime=5;
  if [[ -z $1 ]]; then
    echoErr "Ssh's to a host, retrying every 5 seconds until successful."
    echoErr "Requires terminal-notifier to be on the path."
    echoErr 'usage: sshl <host> <command...>'
    return 1;
  fi;

  local host=$1
  local hostResolved=$(ssh -G "${host}" | awk '$1 == "hostname" { print $2 }');
  shift;

  echoErr "Trying to ssh with:"
  echoErr "  host: $hostResolved"
  echoErr "  time between attempts: ${sleeptime}s"

  while true; do
    ( ssh ${host} 'uptime' > /dev/null 2>&1 ) && break;
    echoErr "$(date) - Not connected [${host}]: sleeping ${sleeptime} seconds";
    sleep ${sleeptime};
  done;

  if [[ $(command -v terminal-notifier) ]]; then
    local endTime=$(current_time_millis)
    terminal-notifier -message "Connected to ${hostResolved} after $(convert_time_string $(($endTime - $startTime)) )";
  fi
  ssh "${host}" "$@"
}

SCRATCHPAD_DIR=~/scratchpad
mkdir -p ${SCRATCHPAD_DIR}
# copy a file into the scratchpad directory
function scratch() {
  local files=("$@")

  if [ ${#files[@]} -eq 0 ]; then
    echoErr "Copies files into the scratchpad directory at [${GREEN}${SCRATCHPAD_DIR}${RESTORE}]"
    echoErr "Usage: scratch <filename ...>"
    return 1
  else
    for f in "${files[@]}"; do
      cp "$f" "${SCRATCHPAD_DIR}"
    done
  fi
}

function httpServe() {
  local directory=${1:-.}
  local port="8000"
  local bindHost="localhost"

  (cd $directory && echo "Serving directory [$(pwd)] on [http://${bindHost}:${port}]..." && python3 -m http.server ${port} --bind ${bindHost})
}

function battery() {
  if [[ "$(command -v pmset)" ]]; then
    local value=$(pmset -g batt | \grep -Eo '[0-9]+%')
    if [[ "${value}" == "" ]]; then
      # nevermind, just carry on
      return 0
    else
      echo "${value}"
    fi
  fi
}

function javaHomePicker() {
  if ! command -v /usr/libexec/java_home > /dev/null; then
    echo "Requires /usr/libexec/java_home"
    return 1
  else
    local version=$1
    if [[ "${version}" == "" ]]; then
      /usr/libexec/java_home -V
      echo
      echo "Usage: javaHomePicker <version>"
    else
      export JAVA_HOME=$(/usr/libexec/java_home -F -v ${version})
    fi
  fi
}

if [[ $(command -v brew) ]]; then
  # track brew installs
  function brew() {
    is_install_command="no"
    for i in "$@"; do
      if [[ "${is_install_command}" == "yes" ]]; then
        echo $i >> "${DOT_FILES_DIR}/config/homebrew-formulae"
      elif [[ "$i" == "install" ]]; then
        is_install_command="yes"
      fi
    done
    sort -u -o "${DOT_FILES_DIR}/config/homebrew-formulae" "${DOT_FILES_DIR}/config/homebrew-formulae"

    "$(which brew)" "$@"
  }
fi

function maybeRunUpdate() {
  local mainCommand=$1
  shift

  local label
  label="$(printf '%-10s\n' [${mainCommand}])"

  if [[ "$(command -v ${mainCommand})" ]]; then
    local result="pass"
    while [[ "$1" != "" ]]; do
      local itemCommand="$1"
      shift

      if [[ "$result" == "pass" ]]; then
        echo "Running update command [$itemCommand]..." | indent "$label" >&2
        (bash -ce "$itemCommand" 2>&1) | indent "$label" >&2

        if [ $? ]; then
          result="pass"
        else
          result="fail"
        fi

      else
        echo "Skipping [$itemCommand] after earlier failure" | indent "$label" >&2
      fi
    done
  else
    echo "${mainCommand} was not found, skipping" | indent "$label" >&2
  fi
}

function runUpdates() {
  if [[ $(type -t machineSpecificRunUpdates) == function ]]; then
    machineSpecificRunUpdates
  else
    echoErr "No machine-specific updaters found"
  fi

  maybeRunUpdate "apt-get" "sudo apt-get update" "sudo apt-get upgrade --yes"
  maybeRunUpdate "brew" "brew update" "brew upgrade" "brew cleanup -s"
  maybeRunUpdate "gcloud" "gcloud components update --quiet"
  maybeRunUpdate "npm" "npm upgrade -g" # update is a synonym
  maybeRunUpdate "mas" "mas upgrade"
}

function man() {
    env \
        LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
        LESS_TERMCAP_md="$(printf "\e[1;31m")" \
        LESS_TERMCAP_me="$(printf "\e[0m")" \
        LESS_TERMCAP_se="$(printf "\e[0m")" \
        LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
        LESS_TERMCAP_ue="$(printf "\e[0m")" \
        LESS_TERMCAP_us="$(printf "\e[1;32m")" \
            man "$@"
}

function is_mac() {
  [[ "$(uname)" =~ "Darwin" ]]
}

function is_linux() {
  [[ "$(uname)" =~ "Linux" ]]
}

function fixBrewVersion() {
  local formula="${1}"
  local version="${2}"

  if [[ "$#" != "2" ]]; then
    echo "Usage:   fixBrewVersion <formula> <version>"
    echo "Example: fixBrewVersion bash 5.2.12"
    return 1
  fi

  echo "Changing linked version of ${formula} to ${version}..."

  local symlinkName="/opt/homebrew/bin/${formula}"
  local formulaDir="/opt/homebrew/Cellar/${formula}"
  local actualBinary="${formulaDir}/${version}/bin/${formula}"

  echo -n "Available versions: "
  ls --color=none -C "${formulaDir}"

  if [[ ! -f "${actualBinary}" ]]; then
    echo "Binary does not exist at: ${actualBinary}"
    return 1
  fi

  if [[ ! -f "${symlinkName}" ]]; then
    echo "Symlink does not exist at: ${symlinkName}"
    return 1
  fi

  ln -sf "${actualBinary}" "${symlinkName}"
  echo "Linked ${formula} version ${version}"
  ls -l "${symlinkName}"
}