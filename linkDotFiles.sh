#!/bin/bash

set -e

DOT_FILES_DIR=$(cd "$(dirname $0)" && pwd)

function create_link() {
	local f="$1"
	ln -sf $DOT_FILES_DIR/$f "$HOME/$(basename $f)"
}

function delete_link() {
	local f="$1"
	rm "$HOME/$(basename $f)"
}

if [[ "$1" == "--remove" ]]; then
	ACTION=delete_link
else
	ACTION=create_link
	if [[ "${SUPPRESS_GIT_CONFIG_EMAIL_MESSAGE:-}" != "yes" ]]; then
		echo "If you need to commit to git, remember to update your email in $HOME/.config/git/config, in a [user].email property."
	fi
fi

for f in .bashrc .bash_profile git/.gitconfig ; do
	$ACTION "$f"
done
