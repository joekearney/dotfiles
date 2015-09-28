#!/bin/bash

set -e

SOURCE_HOME=$(cd ~; pwd)
TARGET_HOST=shell
if [[ $1 != "" ]]; then
  TARGET_HOST=$1
fi
TARGET_HOME=$(ssh $TARGET_HOST "cd ~; pwd")

echo "Copying dot files from [${SOURCE_HOME}] on $(hostname -s) to [${TARGET_HOME}] on $TARGET_HOST"

for f in .bashrc .bash_profile .vimrc; do
  FROM="${SOURCE_HOME}/$f"
  TO="$TARGET_HOST:${TARGET_HOME}"
  echo "Copying [$f] from [$FROM] to [$TO]..."
  scp $FROM $TO
done

ssh $TARGET_HOST "mkdir -p ${TARGET_HOME}/.ssh; chmod 700 ${TARGET_HOME}/.ssh"
scp -r ${SOURCE_HOME}/.ssh/id_rsa* $TARGET_HOST:${TARGET_HOME}/.ssh
