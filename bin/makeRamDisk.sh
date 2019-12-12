#!/usr/bin/env bash

set -euo pipefail

function usage() {
  cat <<-DELIM
Creates a ramdisk with a specified name and size.

$0 <name> <size-in-bytes>
DELIM
  exit 1
}

function mount_ramdisk() {
  local name=$1
  local sizeBytes=$2
  local mountPoint="/Volumes/${name}"

  if [[ -d "${mountPoint}" ]]; then
    echo "[${name}] already exists, mounted at [${mountPoint}]"
  else
    local newMount
    newMount=$(hdiutil attach -nomount ram://${sizeBytes})

    diskutil erasevolume HFS+ "${name}" ${newMount}
  fi
}

if [[ "$#" != "2" ]]; then
  usage
fi

mount_ramdisk $1 $2
