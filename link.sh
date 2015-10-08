#!/bin/bash

DOT_FILE_DIR=$(readlink -f $0 | xargs dirname)

for f in .bashrc .bash_profile .vimrc .git-prompt.sh; do
	ln -sf $DOT_FILE_DIR/$f ~/$(basename $f)
done
