#!/bin/bash

INCLUDE_SSH_CERTS="false"
DO_LINKING="true"

set -euo pipefail

SOURCE_DIR="$(dirname $0)"
source "${SOURCE_DIR}/bash/bash-functions.sh"
source "${SOURCE_DIR}/colour/.bash_color_vars"

SOURCE_HOME="$(cd ~ && pwd)"

function copyFilesTo() {
  local TARGET_HOST=$1
  shift
  local OTHER_DOT_FILES="$*"

  local TARGET_HOST_RESOLVED
  TARGET_HOST_RESOLVED="$(ssh -G ${TARGET_HOST} | awk '$1 == "hostname" { print $2 }')"
  echoErr "Processing for host [${RED}${TARGET_HOST}${RESTORE}], resolved to [${RED}${TARGET_HOST_RESOLVED}${RESTORE}]"

  local TARGET_HOME
  TARGET_HOME=$(ssh ${TARGET_HOST_RESOLVED} "cd ~; pwd")

  local FROM="${SOURCE_HOME}/dotfiles/"
  local TO="${TARGET_HOST}:${TARGET_HOME}/dotfiles"

  echoErr "  [host=${TARGET_HOST}] Rsyncing dotfiles from local [${GREEN}$(hostname -s)${RESTORE}:${GREEN}${FROM}${RESTORE}]"
  echoErr "  [host=${TARGET_HOST}]                    to remote [${RED}${TO}${RESTORE}]"
  runCommand rsync -a $FROM $TO

  for f in ${OTHER_DOT_FILES}; do
    echoErr "  [host=${TARGET_HOST}] Copying [$f] to [${TARGET_HOST}]"
    runCommand scp -qp  "$f" "${TARGET_HOST}:"
  done

  if [[ ${DO_LINKING} == "true" ]]; then
    echoErr "  [host=${TARGET_HOST}] Linking dotfiles on [${TARGET_HOST}]..."
    runCommand ssh -x ${TARGET_HOST} SUPPRESS_GIT_CONFIG_EMAIL_MESSAGE=yes ${TARGET_HOME}/dotfiles/linkDotFiles.sh
  else
    echoErr "  [host=${TARGET_HOST}] skipping linking"
  fi

  if [[ ${INCLUDE_SSH_CERTS} == "true" ]]; then
    echoErr "  [host=${TARGET_HOST}] Copying ssh certificates to [$TARGET_HOST:${TARGET_HOME}]"
    runCommand ssh -x ${TARGET_HOST} "mkdir -p ${TARGET_HOME}/.ssh; chmod 700 ${TARGET_HOME}/.ssh"
    runCommand rsync -a ${SOURCE_HOME}/.ssh/id_rsa* ${TARGET_HOST}:${TARGET_HOME}/.ssh/
  else
    echoErr "  [host=${TARGET_HOST}] skipping copying ssh certs"
  fi

  echoErr
}

if [[ ${1:-} == "" ]]; then
  echoErr "Usage: $0 <target_host> ..."
  exit 1
fi

HOST="${1}"
shift
copyFilesTo $HOST "$@"
