#!/bin/bash

DOT_FILES_DIR=$(dirname $(readlink -f $0))

for f in .bashrc .bash_profile .vimrc .gitconfig .screenrc .inputrc; do
	ln -sf $DOT_FILES_DIR/$f ~/$(basename $f)
done

echo "If you need to commit to git, remember to update your email in $HOME/.config/git/config, in a [user].email property."
