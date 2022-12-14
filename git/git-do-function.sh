#!/bin/bash

. "$(dirname ${0})/git-functions.sh"

functionName=$1
if [[ "$functionName" == "" ]]; then
  echo "Usage: $0 <functionName> [<args>...]"
fi

shift 1

functionArgs="$@"

echo "Calling: $functionName $functionArgs"

$functionName $functionArgs
