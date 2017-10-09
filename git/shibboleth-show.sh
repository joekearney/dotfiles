#!/bin/sh -e

if [ "$NO_SHIBBOLETH" != "" ]; then
  cat "$1"
  exit 0
fi

shibboleth show "$1" | sed 's/^/shibboleth> /g'
