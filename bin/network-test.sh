#!/bin/bash

# requirements:
#         brew install parallel ipconfig httpie
# sudo apt-get install parallel ipconfig httpie

. $DOT_FILES_DIR/colour/.bash_color_vars

TARGETS=$(cat $DOT_FILES_DIR/bin/big-websites.txt)
NUM_TARGETS=$(echo "$TARGETS" | wc -l)

DEFAULT_SUITE_TIMEOUT_SECONDS=2
DEBUG=0

function indent() {
  local prefix=$1
  sed "s/^/$1  /"
}

function runTest() {
  local name=$1
  local op=$2
  local timeout=$3
  if [[ "$timeout" == "" ]]; then
    timeout=$DEFAULT_SUITE_TIMEOUT_SECONDS
  fi

  echo "Running test: $YELLOW$name$RESTORE"

  echo "${TARGETS}" | parallel --timeout $timeout "$op $w {} > /dev/null 2>&1 && (if [ $DEBUG -eq 1 ]; then echo \" |  passed: [$GREEN{}$RESTORE]\"; fi) || (echo \" |  failed: [$RED{}$RESTORE]\"; exit 1)"
  local failed=$?

  if [ $failed -ne 0 ]; then
    echo "failed ${RED}${failed}${RESTORE}/$NUM_TARGETS instances of [$RED$name$RESTORE]" | indent " |"
    PROBLEM_TESTS+=("$name (failed $failed/$NUM_TARGETS)")
  fi

  return $failed
}

function runTestSuite() {
  local PING_TIMEOUT=1
  local DNS_TIMEOUT=1
  local DNS_RETRIES=1
  local HTTP_TIMEOUT=1

  echo "Current DHCP info:"
  ipconfig getpacket en0 | egrep '(yiaddr|router)' | indent " |"

  echo "Current DNS setup is as follows:"
  cat /etc/resolv.conf | grep -v '^#' | indent " |"

  echo
  echo "Testing network connection using $NUM_TARGETS targets..."
  echo

  # not a great way of doing this
  PROBLEM_TESTS=()

  runTest "dns/udp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES"
  #runTest "dns/tcp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES -T"
  runTest "ping" "ping -c 1 -q -t $PING_TIMEOUT"
  runTest "http" "http --headers --timeout $HTTP_TIMEOUT"

  local exitStatus

  echo
  echo -n "All tests completed"
  if [ "${#PROBLEM_TESTS[@]}" -gt 0 ]; then
    echo ". There were problems in these tests:"
    for p in "${PROBLEM_TESTS[@]}"; do
      echo "  $p"
    done
    exitStatus=1
  else
    echo " ${GREEN}successfully${RESTORE}"
    exitStatus=0
  fi

  unset PROBLEM_TESTS
  return $exitStatus
}

if [[ "$1" == "-v" ]]; then
  echo "Running in debug mode"
  DEBUG=1
else
  DEBUG=0
fi

runTestSuite
