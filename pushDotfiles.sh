#!/bin/bash

ECHO_ONLY=false
INCLUDE_SSH_CERTS=false
DO_LINKING=true

set -e

SOURCE_DIR=$(dirname $0)
source ${SOURCE_DIR}/functions.sh
source ${SOURCE_DIR}/colour/.bash_color_vars

SOURCE_HOME=$(cd ~; pwd)

function copyFilesTo() {
  local TARGET_HOST=$1
  local TARGET_HOME=$(ssh $TARGET_HOST "cd ~; pwd")

  local FROM="${SOURCE_HOME}/dotfiles/"
  local TO="$TARGET_HOST:${TARGET_HOME}/dotfiles"

  echo "  [host=${TARGET_HOST}] Rsyncing dotfiles from [${GREEN}${FROM}${RESTORE}] on local host [${GREEN}$(hostname -s)${RESTORE}] to [${RED}${TO}${RESTORE}]"
  runCommand rsync -a $FROM $TO

  if [[ ${DO_LINKING} == "true" ]]; then
    echo "  [host=${TARGET_HOST}] Linking dotfiles on [${TARGET_HOST}]"
    runCommand ssh -x $TARGET_HOST "~/dotfiles/linkDotFiles.sh"
  else
    echo "  [host=${TARGET_HOST}] skipping linking"
  fi

  if [[ ${INCLUDE_SSH_CERTS} == "true" ]]; then
    echo "  [host=${TARGET_HOST}] Copying ssh certificates to [$TARGET_HOST:${TARGET_HOME}]"
    runCommand ssh -x $TARGET_HOST "mkdir -p ${TARGET_HOME}/.ssh; chmod 700 ${TARGET_HOME}/.ssh"
    runCommand rsync -a ${SOURCE_HOME}/.ssh/id_rsa* $TARGET_HOST:${TARGET_HOME}/.ssh/
  else
    echo "  [host=${TARGET_HOST}] skipping ssh"
  fi
}

if [[ $1 == "" ]]; then
  echo "Usage: $0 <target_host> ..."
  exit 1
fi

for h in "$@"; do
  echo "Processing for host [$RED$h$RESTORE]"
  copyFilesTo $h
  echo
done
