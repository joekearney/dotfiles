#!/bin/bash

# requirements:
#         brew install parallel ipconfig httpie
# sudo apt-get install parallel ipconfig httpie

TARGETS=$(cat $DOT_FILES_DIR/big-websites.txt)
NUM_TARGETS=$(echo "$TARGETS" | wc -l)

function indent() {
  sed 's/^/ |  /'
}

function runTest() {
  local name=$1
  local op=$2
  echo "Running test: $name"

  echo "${TARGETS}" | parallel "$op $w {} > /dev/null"
  local failed=$?

  if [ $failed -gt 0 ]; then
    echo " | failed $failed/$NUM_TARGETS instances of [$name]"
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
  ipconfig getpacket en0 | egrep '(yiaddr|router)' | indent

  echo "Current DNS setup is as follows:"
  cat /etc/resolv.conf | grep -v '^#' | indent

  echo
  echo "Testing network connection using $NUM_TARGETS targets..."
  echo

  # not a great way of doing this
  PROBLEM_TESTS=()

  runTest "dns lookup over udp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES"
  runTest "dns lookup over tcp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES -T"
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
    echo " successfully"
    exitStatus=0
  fi

  unset PROBLEM_TESTS
  return $exitStatus
}

runTestSuite
