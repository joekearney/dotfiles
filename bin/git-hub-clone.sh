#|/bin/bash

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
    local target="~/git/$org/$repo"
    echo "Cloning from [${RED}$url${RESTORE}] into [${GREEN}${target}${RESTORE}] "
    git clone $url $target;
  fi
}

gitHubClone "$@"
