function runCommand() {
  if [[ "${ECHO_ONLY}" == "true" ]]; then
    echo "    [runCommand] $@"
  else
    "$@"
  fi
}

function countdown() {
  local remaining=$1
  while ((remaining>0)); do
    echo $remaining
    sleep 1
    ((remaining=remaining-1))
  done
}

function shellTitle() {
    echo -ne "\033]0;"$*"\007"
}

# head and grep
function hag() {
  sed -e '1p' -e "/$1/!d"
}

function ash() {
  if [[ $1 == "" ]]; then
    # delegate to the error that ssh gives with no args
    ssh
  else
    local target_host=$1
    LC_alias_of_target_host=$target_host ssh $target_host
  fi
}

function getExpectedHostname() {
  if [ ! -z "$LC_alias_of_target_host" ]; then
    echo "$LC_alias_of_target_host"
  else
    hostname -s
  fi
}
