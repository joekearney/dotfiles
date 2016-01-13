#!/bin/bash

TARGETS=$(cat $DOT_FILES_DIR/big-websites.txt)
NUM_TARGETS=$(echo "$TARGETS" | wc -l)

echo "Testing network connection using $NUM_TARGETS targets..."
echo

PROBLEM_TESTS=()

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
      failed=1
      echo " + Failed test [$name] on [$w], with exit code [$result]"
      echo "$output" | sed 's/^/ |  /'
    fi
  done

  if [ $failed -eq 1 ]; then
    PROBLEM_TESTS+=("$name")
  fi
}

PING_TIMEOUT=2
DNS_TIMEOUT=1
DNS_RETRIES=1

runTest "dns lookup over udp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES"
runTest "dns lookup over tcp" "host -W $DNS_TIMEOUT -R $DNS_RETRIES -T"
runTest "ping" "ping -oq -t $PING_TIMEOUT"
runTest "http" "http --headers"

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
