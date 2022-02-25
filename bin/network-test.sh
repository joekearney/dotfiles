#!/usr/bin/env bash

set -u
set -e

# requirements:
#         brew install parallel ipconfig httpie
# sudo apt-get install parallel ipconfig httpie

if ! command -v parallel; then
  echo "GNU Parallel is required"
  echo "  brew install parallel"
  exit 1
fi

. $DOT_FILES_DIR/colour/.bash_color_vars

function echoErr() {
  cat <<< "$@" 1>&2
}

# https://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'network_test_temp_dir')
trap "rm -rf ${TEMP_DIR}" EXIT

readarray -t TARGETS < <(egrep -v "^#" $DOT_FILES_DIR/bin/big-websites.txt)
NUM_TARGETS="${#TARGETS[@]}"

DEFAULT_SUITE_TIMEOUT_SECONDS=2
DEBUG=0

function indent() {
  local prefix=$1
  sed "s/^/$1  /"
}

function runTest() {
  local name=$1
  local op=$2
  local timeout=${3:-}
  if [[ "$timeout" == "" ]]; then
    timeout=$DEFAULT_SUITE_TIMEOUT_SECONDS
  fi

  echoErr "Running test: $YELLOW$name$RESTORE"

  local resultsFile=$(mktemp ${TEMP_DIR}/network_test_temp.XXXX)
  printf "%s\n" "${TARGETS[@]}" | parallel \
    --timeout $timeout \
    --joblog ${resultsFile} \
    "$op {}" > /dev/null 2>&1

  # echoErr "  | Results file: ${resultsFile}"

  # first line is header
  # select those lines with non-zero exitval, in column 7
  # print target 0-based index computed from 1-based sequence
  local failedTargets
  readarray -t failedTargets < <(tail -n +2 ${resultsFile} | awk '$7 != 0 { print ($1 - 1)}')

  local numFailedTargets="${#failedTargets[@]}"

  if [ $numFailedTargets -ne 0 ]; then
    for index in "${failedTargets[@]}"; do
      echoErr "  | failed: [${RED}${TARGETS[${index}]}${RESTORE}]"
    done
    echoErr "  | failed ${RED}${numFailedTargets}${RESTORE}/$NUM_TARGETS instances of [$RED$name$RESTORE]"
  fi

  echo $numFailedTargets
}

function runTestSuite() {
  local PING_TIMEOUT=1
  local DNS_TIMEOUT=1
  local DNS_RETRIES=1
  local HTTP_TIMEOUT=1

  echo "Current DHCP info:"
  ipconfig getpacket en0 | egrep '(yiaddr|router|domain_name_server)' | indent " |"

  echo "Current resolv.conf DNS setup is as follows:"
  cat /etc/resolv.conf | grep -v '^#' | indent " |"

  local -A tests
  tests["dns/udp"]="host -W $DNS_TIMEOUT -R $DNS_RETRIES"
  tests["dns/tcp"]="host -W $DNS_TIMEOUT -R $DNS_RETRIES -T"
  tests["ping"]="ping -c 1 -q -t $PING_TIMEOUT"
  tests["http"]="http --headers --timeout $HTTP_TIMEOUT"
  local testsOrdered=("dns/udp" "dns/tcp" "ping" "http")

  echo
  echo "Testing network connection using $NUM_TARGETS targets..."
  echo

  local -A results
  local totalProblems=0

  for testName in "${testsOrdered[@]}"; do
    local testCommand="${tests[${testName}]}"

    if [[ "$testCommand" != "" ]]; then
      local result=$(runTest "${testName}" "${testCommand}")

      results["${testName}"]="${result}"
      totalProblems=$((totalProblems + result))
    fi
  done

  echo
  if [ "${totalProblems}" -gt 0 ]; then
    echo "All tests completed. There were failures in ${totalProblems} tests:"
    for testName in "${testsOrdered[@]}"; do
      local result="${results[${testName}]}"
      if [[ "$result" != "0" ]]; then
        printf "  | %-12s %3s/%s\n" ${testName} ${result} ${NUM_TARGETS}
      fi
    done
    return 1
  else
    echo "All tests completed ${GREEN}successfully${RESTORE}"
    return 0
  fi
}

if [[ "${1:-}" == "-v" ]]; then
  echo "Running in debug mode"
  DEBUG=1
else
  DEBUG=0
fi

runTestSuite
