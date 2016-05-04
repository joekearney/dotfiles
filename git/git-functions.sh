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
      echo -e "Found no directories matching [${RED}$repoName${RESTORE}]"
    fi
  fi
}
# bash auto completion for g commands.
# This actually gives the list of repos on all arg positions of g, where really
# we'd only want it on the second arg. TODO improve? It's also useful for
# pre-canned commands like cdg and atomg
function _do_with_git_complete_options() {
  local curr_arg=${COMP_WORDS[COMP_CWORD]}
  # get the list of git repos in known positions
  # this comment syntax for a multiline command is a pretty horrific abuse of
  # substitution, inspired by this: http://stackoverflow.com/questions/9522631
  local repos=$(find                                                                       \
          ~/git                           `# assumed base of where all of your repos live` \
          -type d                         `# looking for directories`                      \
          -mindepth 2 -maxdepth 3         `# either at ~/git/*/.git or ~/git/*/*/.git`     \
          -name ".git" |                  `# called .git`                                  \
            awk -F/ '{ print $(NF-1) }'   `# and get the name of the dir containing .git`  \
        )
  COMPREPLY=( $(compgen -W '${repos[@]}' -- $curr_arg ) )
}

complete -F _do_with_git_complete_options g

# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function cdg() {
  g "cd" $1
}
# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function atomg() {
  g "atom" $1
}
complete -F _do_with_git_complete_options cdg
complete -F _do_with_git_complete_options atomg

function gitSetUpSbtSymlinks() {
  if [[ "$#" != 1 ]]; then
    echo "Usage: gitSetUpSbtSymlinks <repo-dir>"
    return 1
  else
    local repo=$1
    ln -sf ~/.ivy2 $repo/.ivy2
#    ln -sf ~/.sbt $repo/.sbt
  fi
}

function gitHubClone() {
  if [[ $1 == '' ]]; then
    echo 'Usage: git hub [<org>] <repo>';
    exit 1;
  fi;
  if [[ $2 == '' ]]; then
    local repo=$1;
    local org=$(pwd | xargs basename);
    local url=git@github.com:$org/$repo.git;
    echo "Cloning from [${YELLOW}$url${RESTORE}] into [${GREEN}$(pwd)/$repo${RESTORE}]...";
    git clone $url;
    gitSetUpSbtSymlinks $repo
  else
    local org=$1;
    local repo=$2;
    local url=git@github.com:$org/$repo.git;
    local target="$HOME/git/$org/$repo"
    echo "Cloning from [${YELLOW}$url${RESTORE}] into [${GREEN}${target}${RESTORE}]..."
    git clone $url $target;
    gitSetUpSbtSymlinks $target
  fi
}

function gitMoveCommitsTo() {
  if [[ "$#" != 2 ]]; then
    echo "Usage: gitMoveCommitsTo <branchName> <numCommits>"
    return 1
  fi
  local branchName=$1
  local numCommits=$2

  git branch $branchName && git reset --hard HEAD~$numCommits && git checkout $branchName
}
