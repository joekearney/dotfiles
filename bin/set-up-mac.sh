#!/usr/bin/env bash

DOTFILES_BIN=~/dotfiles/bin

function installHomebrew() {
  if [[ $(command -v brew) ]]; then
    echo "brew already installed"
    return
  fi
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function setupDotFiles() {
  (cd ~ && PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH" dotfiles/linkDotFiles.sh)
}

function installBash4() {
  brew install bash
  ${DOTFILES_BIN}/mac-use-bash-4.sh
}

#installHomebrew
#installBash4
#${DOTFILES_BIN}/install-gnu-tools.sh
setupDotFiles

#$(DOTFILES_BIN)/run-updates
