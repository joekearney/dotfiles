#!/bin/bash

DOT_FILE_DIR=$(dirname $0)

for f in $(find $DOT_FILE_DIR -maxdepth 1 -type f -name '.*'); do
	ln -s $f ~/$(basename $f)
done