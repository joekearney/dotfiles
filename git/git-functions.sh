#!/bin/bash

# do something given a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function g() {
  if [[ "$1" == "" || "$2" == "" ]]; then
    echo "Usage: ${FUNCNAME[0]} <operation> <repo-name>"
  else
    local operation=$1
    local repoName=$2
    local path=($(find ~/git -type d -maxdepth 3 -name ".git" | egrep -i "/[^/]*${repoName}[^/]*/.git" | xargs dirname))

    local count=${#path[@]}

    if [[ "$count" == "1" ]]; then
      $operation $path
    elif (( $count > 1 )); then
      echo -e "Found $count directories matching [${WHITE}$repoName${RESTORE}]"
      local index=1
      for p in "${path[@]}"; do
        local head=$(dirname $p)
        local tail=$(basename $p)
        echo "  [${GREEN}$index${RESTORE}] ${head}/${GREEN}${tail}${RESTORE}"
        ((index=index+1))
      done

      echo -n "Enter an repo to use, or <enter> to stop: "
      read g
      if [[ "$g" != "" ]]; then
        ((gotoIndex=g-1))
        $operation ${path[gotoIndex]}
      fi
    else
      echo -e "Found no directories matching [$repoName]"
    fi
  fi
}
# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function cdg() {
  g "cd" $1
}
# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function atomg() {
  g "atom" $1
}
# bash auto completion for cdg
function _do_with_git_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  local lines=$(find ~/git -type d -maxdepth 3 -name ".git" | awk -F/ '{ print $(NF-1) }')
  COMPREPLY=( $(compgen -W '${lines[@]}' -- $curr_arg ) )
}
complete -F _do_with_git_complete_options cdg
complete -F _do_with_git_complete_options atomg
complete -F _do_with_git_complete_options g

gitHubClone() {
  if [[ $1 == '' ]]; then
    echo 'Usage: git hub [<org>] <repo>';
    exit 1;
  fi;
  if [[ $2 == '' ]]; then
    local repo=$1;
    local org=$(pwd | xargs basename);
    local url=git@github.com:$org/$repo.git;
    echo "Cloning from [${RED}$url${RESTORE}] into [${GREEN}$(pwd)/$repo${RESTORE}]";
    git clone $url;
  else
    local org=$1;
    local repo=$2;
    local url=git@github.com:$org/$repo.git;
    local target="$HOME/git/$org/$repo"
    echo "Cloning from [${RED}$url${RESTORE}] into [${GREEN}${target}${RESTORE}] "
    git clone $url $target;
  fi
}
