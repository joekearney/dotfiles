#!/bin/bash

set -e

DOT_FILES_DIR=$(dirname $(readlink -f $0))

for f in .bashrc .bash_profile .vimrc git/.gitconfig .screenrc .inputrc; do
	ln -sf $DOT_FILES_DIR/$f ~/$(basename $f)
done

DROPBOX_LOCAL_ENV="~/Dropbox/.local_env.sh"
if [[ -f "${DROPBOX_LOCAL_ENV}" ]]; then
	ln -s "${DROPBOX_LOCAL_ENV}" $(basename "${DROPBOX_LOCAL_ENV}")
fi

echo "If you need to commit to git, remember to update your email in $HOME/.config/git/config, in a [user].email property."
