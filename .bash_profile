#!/bin/bash

if [ -f "$HOME/.bashrc" ]; then
  source "$HOME/.bashrc"
fi
[[ -z "${ZSH_VERSION}" && -e "/Users/kearneyjoe/mdproxy/data/mdproxy_bash_profile" ]] && source "/Users/kearneyjoe/mdproxy/data/mdproxy_bash_profile" # MDPROXY-BASH-PROFILE
