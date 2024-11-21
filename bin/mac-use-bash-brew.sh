#!/usr/bin/env bash

set -euo pipefail

BREW_BASH_PATH=/opt/homebrew/bin/bash

if [[ "${1:-}" == "--check" ]]; then
  if [[ "$(which bash)" == "${BREW_BASH_PATH}" ]]; then
    exit 0
  else
    exit 1
  fi
fi

if ! grep ${BREW_BASH_PATH} /etc/shells; then
  echo ${BREW_BASH_PATH} | sudo tee -a /etc/shells
fi

chsh -s ${BREW_BASH_PATH}
sudo chsh -s ${BREW_BASH_PATH}
