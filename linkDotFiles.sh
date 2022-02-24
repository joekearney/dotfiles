#!/bin/bash

set -e

DOT_FILES_DIR=$(cd $(dirname $0) && pwd)

function echoErr() {
  cat <<< "$@" 1>&2
}

for f in .bashrc .bash_profile .vimrc git/.gitconfig .screenrc .inputrc; do
	ln -sf $DOT_FILES_DIR/$f ~/$(basename $f)
done

DROPBOX_LOCAL_ENV="~/Dropbox/.local_env.sh"
if [[ -f "${DROPBOX_LOCAL_ENV}" ]]; then
	ln -s "${DROPBOX_LOCAL_ENV}" $(basename "${DROPBOX_LOCAL_ENV}")
fi

if [[ ${SUPPRESS_GIT_CONFIG_EMAIL_MESSAGE} != "yes" ]]; then
	echoErr "If you need to commit to git, remember to update your email in $HOME/.config/git/config, in a [user].email property."
fi
