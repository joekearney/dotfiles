#!/bin/bash

CODE_ROOT=$(cd ~/git/src; pwd)
# TODO eventually ${CODE_ROOT}
GITHUB_ROOT=${CODE_ROOT}/github.com

# do something given a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function g() {
  if [[ "$1" == "" || "$2" == "" ]]; then
    echo "Usage: ${FUNCNAME[0]} <repo-name> <operation>"
    return 1
  else
    local repoName=$1
    shift 1
    local operation="$@"
    local paths=($(find ${CODE_ROOT} -maxdepth 4 -type d -name ".git" -or -name "src" | egrep -i "/[^/]*${repoName}[^/]*/(.git|src)" | xargs dirname | sort -u))

    local count=${#paths[@]}

    if [[ "$count" == "1" ]]; then
      $operation $paths
      return $?
    elif (( $count > 1 )); then
      echo -e "Found $count directories matching [${WHITE}$repoName${RESTORE}]"
      local index=1
      for path in "${paths[@]}"; do
        local parentDir=$(dirname $path)
        local head=$(dirname $parentDir)
        local middle=$(basename $parentDir)
        local tail=$(basename $path)
        echo "  [${GREEN}$index${RESTORE}] ${head}/${YELLOW}${middle}${RESTORE}/${GREEN}${tail}${RESTORE}"
        ((index=index+1))
      done

      echo -n "Enter an repo to use, or <enter> to stop: "
      read g
      if [[ "$g" != "" ]]; then
        if [[ "$g" -le "$count" ]]; then
          ((gotoIndex=g-1))
          $operation ${paths[gotoIndex]}
          return $?
        else
          echo -e "Invalid index [${RED}$g${RESTORE}]"
          return 1
        fi
      fi
    else
      echo -e "Found no directories matching [${RED}$repoName${RESTORE}]"
      return 1
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
          ${CODE_ROOT}                    `# assumed base of where all of your repos live` \
          -mindepth 2 -maxdepth 4         `# either at ${CODE_ROOT}/*/.git or ${CODE_ROOT}/*/*/.git`     \
          -type d                         `# looking for directories`                      \
          -name ".git" -or -name "src" |  `# called .git or src`                           \
          awk -F/ '{ print $(NF-1) }'  |  `# and get the name of the dir containing .git`  \
          sort -u                         `# and remove duplucates`                        \
        )
  COMPREPLY=( $(compgen -W '${repos[@]}' -- $curr_arg ) )
}

complete -F _do_with_git_complete_options g

# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function cdg() {
  g $1 "cd"
  return $?
}
# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name,
# and do git pull
function cdgp() {
  cdg $1 && git pull
}

# Pulls a repo up to date, switches to that directory, and opens it in Atom
function cdga() {
  local repoIsh=$1

  if cdg ${repoIsh}; then
    local thisDir=$(basename ${PWD})
    local parentDir=$(basename $(dirname ${PWD}))
    local prettyName=${GREEN}${parentDir}/${thisDir}${RESTORE}

    echo "Synchronising Git repo [${prettyName}]..." && \
    git pull && \
    echo "Opening Atom in Git repo [${prettyName}]..." && \
    atom .
  fi
}

# cd to a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function atomg() {
  g $1 "atom"
}
complete -F _do_with_git_complete_options cdg
complete -F _do_with_git_complete_options cdgp
complete -F _do_with_git_complete_options cdga
complete -F _do_with_git_complete_options atomg

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
  else
    local org=$1;
    local repo=$2;
    local url=git@github.com:$org/$repo.git;
    local target="${GITHUB_ROOT}/$org/$repo"
    echo "Cloning from [${YELLOW}$url${RESTORE}] into [${GREEN}${target}${RESTORE}]..."
    git clone $url $target;
  fi
}

function gitMoveCommitsTo() {
  if [[ "$#" != 2 ]]; then
    echo "Usage: gitMoveCommitsTo <branchName> <numCommits>"
    echo
    echo "Note that this involves a git reset --hard, so will delete anything not committed"
    echo "on the current branch. Stash, commit or otherwise save your changes first."
    return 1
  fi
  local branchName=joe/$1
  local numCommits=$2

  git branch $branchName && git reset --hard HEAD~$numCommits && git checkout $branchName
}

function gitKnifeCookbookBump() {
  if [[ "$#" != 1 ]]; then
    echo "Usage: gitKnifeCookbookBump <cookbook>"
    return 1
  fi
  local cookbookName=$1

  knife spork bump ${cookbookName} && \
    git commit -m "Bump ${cookbookName} cookbook version" cookbooks/${cookbookName}/metadata.rb && \
    git push && \
    knife spork upload ${cookbookName}
}

# like tree, but attempting to ignore git-ignored files
# this isn't complete -- some gitignore entries are not applied here
# example: "/dirname" won't remove something called "dirname" from
# anywhere in the tree, because to do so removes too much
function gtree() {
  local globalFile=$( git config --get core.excludesfile )
  local localFile="$( git root )/.gitignore"

  globalFile="${globalFile/#\~/$HOME}"
  localFile="${localFile/#\~/$HOME}"

  local extantFiles=""
  for file in ${globalFile} ${localFile}; do
    if [[ -f ${file} ]]; then
      extantFiles="${file} ${extantFiles}"
    fi
  done

  if [[ "${extantFiles}" != "" ]]; then
    local excludesPattern=$(echo "${extantFiles}" | xargs cat | grep -E -v "(^$|^#)" | sed -E 's|/$||' | tr '\n' '\|' )
    \tree -C -I "^(${excludesPattern})$" "${@}"
  else
    \tree -C "${@}"
  fi
}
