#!/bin/bash

CODE_ROOT="$(cd ~ && pwd)/git/src"

function findGitRepoPaths() {
  local repoName=${1}
  find ${CODE_ROOT} -maxdepth 4 -type d -name ".git" | \
    egrep -i "/[^/]*${repoName}[^/]*/(.git|src)" | \
    xargs dirname | \
    sort -u
}

function listGitRepos() {
  findGitRepoPaths ".*" | xargs basename
}

# do something given a directory at git/<name> or git/parent/<name> by giving a substring of the repo name
function g() {
  if [[ "$1" == "" || "$2" == "" ]]; then
    echoErr "Usage: ${FUNCNAME[0]} <repo-name> <operation>"
    echoErr ""
    echoErr "Passes the directory of the repo to the operation as an argument"
    echoErr "Example:"
    echoErr "  g <repo> atom"
    echoErr "runs:"
    echoErr "  atom <repo-dir>"
    return 1
  else
    local repoName=$1
    shift 1
    local operation="$*"

    local paths=()
    while IFS='' read -r line; do
      paths+=("$line")
    done < <(findGitRepoPaths "${repoName}")

    local count=${#paths[@]}

    if [[ "$count" == "1" ]]; then
      $operation "${paths[0]}"
      return $?
    elif (( $count > 1 )); then
      local index=1
      for path in "${paths[@]}"; do
        local parentDir=$(dirname $path)
        local head=$(dirname $parentDir)
        local middle=$(basename $parentDir)
        local tail=$(basename $path)
        echoErr "  [${GREEN}$index${RESTORE}] ${head}/${YELLOW}${middle}${RESTORE}/${GREEN}${tail}${RESTORE}"
        ((index=index+1))
      done

      echoErr -n "Enter an repo to use, or <enter> to stop: "
      read g
      if [[ "$g" != "" ]]; then
        if [[ "$g" -le "$count" ]]; then
          ((gotoIndex=g-1))
          $operation ${paths[gotoIndex]}
          return $?
        else
          echoErr -e "Invalid index [${RED}$g${RESTORE}]"
          return 1
        fi
      fi
    else
      echoErr -e "Found no directories matching [${RED}$repoName${RESTORE}]"
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
  declare -a repos

  # this comment syntax for a multiline command is a pretty horrific abuse of
  # substitution, inspired by this: http://stackoverflow.com/questions/9522631
  repos=$(find                                                                       \
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

function codeg() {
  g $1 "code"
}
function atomg() {
  g $1 "atom"
}

for c in cdg atomg codeg; do
  complete -F _do_with_git_complete_options "$c"
done

function gitClone() {
  if [[ "$#" != "3" ]]; then
    echo "Usage: git (github|bitbucket) [<org>] <repo>"
    exit 1
  fi

  case "$1" in
    github)
      local remoteHost="github.com"
      ;;
    bitbucket)
      local remoteHost="bitbucket.org"
      ;;
    *)
      echo "Usage: git (github|bitbucket) [<org>] <repo>"
      exit 1
  esac

  local org=$2;
  local repo=$3;
  local url=git@${remoteHost}:$org/$repo.git;
  local target="${CODE_ROOT}/${remoteHost}/$org/$repo"
  echo "Cloning from [${YELLOW}$url${RESTORE}] into [${GREEN}${target}${RESTORE}]..."
  git clone $url $target;
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
