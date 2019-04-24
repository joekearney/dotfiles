#!/usr/bin/env bash

BREW_BASH_PATH=/usr/local/bin/bash

if [[ "$1" == "--check" ]]; then
  if [[ "$(which bash)" == "${BREW_BASH_PATH}" ]]; then
    exit 0
  else
    exit 1
  fi
fi

if ! grep -v ${BREW_BASH_PATH} /etc/shells; then
  echo /usr/local/bin/bash | sudo tee -a /etc/shells
fi

chsh -s /usr/local/bin/bash
sudo chsh -s /usr/local/bin/bash
