#!/usr/bin/env bash

set -e

DOTFILES_DIR=~/dotfiles
DOTFILES_BIN=${DOTFILES_DIR}/bin

function echoErr() {
  (>&2 echo "$@")
}

function installHomebrew() {
  if command -v brew; then
    echoErr "brew already installed"
    return
  else
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

function installBash4() {
  if brew list bash --versions | grep --quiet "bash 4"; then
    echoErr "bash 4 already installed"
  else
    brew install bash
    ${DOTFILES_BIN}/mac-use-bash-4.sh
  fi
}

function setupDotFiles() {
  if [[ -d "${DOTFILES_DIR}" ]]; then
    (cd ~ && PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH" ${DOTFILES_DIR}/linkDotFiles.sh)
  else
    echoErr "Expected [dotfiles] directory in PWD [$(pwd)]"
  fi
}

function maybeInstall() {
  local package=$1
  shift
  if brew list ${package} --versions > /dev/null; then
    echoErr "[brew install] ${package} already installed, skipping"
  else
    echoErr "[brew install] ${package} not yet installed, installing now..."
    brew install ${package} $@
  fi
}

function installBrewThings() {
  echoErr "[brew install] Installing a bunch of brew packages..."
  brew install \
    bash-completion tree bats \
    httpie \
    git maven sbt \
    parallel pdsh gpg \
    pup jq diff-so-fancy xmlstarlet imagemagick shellcheck graphviz \
    awscli \
    libxml2 sox ffmpeg
}

function installDocker() {
  if brew cask list docker > /dev/null; then
    echo "Docker already installed"
  else
    brew cask install docker
    etc=/Applications/Docker.app/Contents/Resources/etc
    target=$(brew --prefix)/etc/bash_completion.d
    ln -s ${etc}/docker.bash-completion ${target}/docker
    ln -s ${etc}/docker-machine.bash-completion ${target}/docker-machine
    ln -s ${etc}/docker-compose.bash-completion ${target}/docker-compose
  fi
}

function installFonts() {
  brew tap caskroom/fonts
  brew cask install font-fira-code
}

function installRvm() {
  if [ -d ~/.rvm/ ]; then
    echo "RVM already installed"
  else
    echo "Installing RVM"
    # first line is what rvm.io says to do normally
    # seconf line is the fallback
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
      || curl -sSL https://rvm.io/mpapis.asc | gpg --import -
    \curl -sSL https://get.rvm.io | bash -s stable

    rvm install 2.4
  fi
}

installHomebrew
installBash4
setupDotFiles

# Refer: https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/
maybeInstall coreutils
maybeInstall binutils
maybeInstall diffutils
maybeInstall ed --with-default-names
maybeInstall findutils --with-default-names
maybeInstall gawk
maybeInstall gnu-indent --with-default-names
maybeInstall gnu-sed --with-default-names
maybeInstall gnu-tar --with-default-names
maybeInstall gnu-which --with-default-names
maybeInstall gnutls
maybeInstall grep --with-default-names
maybeInstall gzip lzip
maybeInstall screen
maybeInstall watch
maybeInstall wdiff --with-gettext
maybeInstall wget

installBrewThings

installRvm

${DOTFILES_BIN}/run-updates
