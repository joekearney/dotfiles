#!/bin/bash

TARGETS=$(cat $DOT_FILES_DIR/big-websites.txt)
NUM_TARGETS=$(echo "$TARGETS" | wc -l)

function runTest() {
  local name=$1
  local op=$2
  local failed=0
  echo "Running test: $name"
  for w in $TARGETS; do
    local output
    output=$($op $w 2>&1)
    result=$?
    if [ $result -ne 0 ]; then
      ((failed=failed+1))
      echo " + Failed test [$name] on [$w], with exit code [$result]"
      echo "$output" | sed 's/^/ |  /'
    fi
  done

  if [ $failed -gt 0 ]; then
    PROBLEM_TESTS+=("$name (failed $failed)")
  fi

  return $failed
}

function runTestSuite() {
  local PING_TIMEOUT=1
  local DNS_TIMEOUT=1
  local DNS_RETRIES=1
  local HTTP_TIMEOUT=1

  echo "Testing network connection using $NUM_TARGETS targets..."
  echo

  local PROBLEM_TESTS=()

  runTest "dns lookup over udp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES"
  runTest "dns lookup over tcp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES -T"
  runTest "ping" "ping -oq -t $PING_TIMEOUT"
  runTest "http" "http --headers --timeout $HTTP_TIMEOUT"

  echo
  echo "All tests completed"
  if [ "${#PROBLEM_TESTS[@]}" -gt 1 ]; then
    echo "There were problems in these tests:"
    for p in "${PROBLEM_TESTS[@]}"; do
      echo "  $p"
    done
    exit 1
  else
    exit
  fi
}

function runUntilFailed() {
  local keepGoing=1

#  if [ $keepGoing -gt 0 ]; then
#    echo running
#    keepGoing=runTestSuite
#  fi
}

if [[ "$1" == "-r" ]]; then
  runUntilFailed
else
  runTestSuite
fi
