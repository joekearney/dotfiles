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

# let cd also pushd directories into stack. Use popd to reverse stack
function cd() {
  if [[ "$1" == "" ]]; then
    pushd ~ &> /dev/null
  elif [[ "$1" == "-" ]]; then
    popd &> /dev/null
  elif [[ "$1" == "?" ]]; then
    dirs -v
  elif [ -e $1 ]; then
    pushd $1 &> /dev/null   #dont display current stack
  fi
}

# do something given a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function g() {
  if [[ "$1" == "" || "$2" == "" ]]; then
    echo "Usage: ${FUNCNAME[0]} <operation> <repo-name>"
  else
    local operation=$1
    local repoName=$2
    local path=$(find ~/git -type d -maxdepth 2 -name "*$repoName*")

    # wc counts newlines, so doesn't work to disambiguate 0/1 lines
    local count
    if [[ "$path" == "" ]]; then
      count=0
    else
      count=$(echo "$path" | wc -l)
    fi

    if [[ "$count" == "1" ]]; then
      $operation $path
    elif (( $count > 1 )); then
      echo -e "Found $count directories matching [$repoName]:\n$(echo "$path" | sed 's/^/  /')"
    else
      echo -e "Found no directories matching [$repoName]"
    fi
  fi
}
# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function cdg() {
  g "cd" $1
}
# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function atomg() {
  g "atom" $1
}
# bash auto completion for cdg
function _do_with_git_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  local lines=$(find ~/git -type d -maxdepth 3 -name ".git" | awk -F/ '{ print $(NF-1) }')
  COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
}
complete -F _do_with_git_complete_options cdg
complete -F _do_with_git_complete_options atomg
complete -F _do_with_git_complete_options g

# pipe from http to less, for a given URL
function httpless() {
  # --print=hb means print response headers and response body.
  http --pretty=all --print=hb "$@" | less
}
