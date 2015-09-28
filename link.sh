#!/bin/bash

DOT_FILE_DIR=$(dirname $0)

for f in $(ls -d $DOT_FILE_DIR/.[^.]*); do
	ln -s $f ~/$(basename $f)
done