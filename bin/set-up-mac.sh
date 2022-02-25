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
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

function installBashBrew() {
  if ${DOTFILES_BIN}/mac-use-bash-brew.sh --check; then
    echoErr "bash already installed"
  else
    brew install bash
    ${DOTFILES_BIN}/mac-use-bash-brew.sh
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
    brew install ${package} "$@"
  fi
}

function installBrewThings() {
  echoErr "[brew install] Installing a bunch of brew packages..."

  brew install \
    gzip lzip \
    bash-completion tree htop shellcheck \
    coreutils findutils gnu-tar gnu-sed gawk gnutls gnu-indent gnu-getopt grep

  # watch httpie git maven sbt parallel pdsh gpg pup jq diff-so-fancy xmlstarlet imagemagick shellcheck graphviz awscli libxml2 sox ffmpeg

  # brew cask install balenaetcher
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

function installJava() {
  if brew tap | grep -v "adoptopenjdk/openjdk"; then
    echo "Java tap already installed"
  else
    brew tap AdoptOpenJDK/openjdk
  fi

  if brew cask list adoptopenjdk > /dev/null; then
    echo "Java already installed"
  else
    brew cask install adoptopenjdk8
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

    rvm install 2.5
  fi
}

installHomebrew
installBashBrew

installBrewThings
installFonts
# installDocker
# installJava

# installRvm

setupDotFiles

# load everything !!!
source ~/.bashrc

${DOTFILES_BIN}/run-updates
