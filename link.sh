#!/bin/bash

for f in .bashrc .bash_profile .vimrc .git-prompt.sh .gitconfig; do
	ln -sf $DOT_FILES_DIR/$f ~/$(basename $f)
done

echo "If you need to commit to git, remember to update your email in $HOME/.config/git/config, in a [user].email property."
