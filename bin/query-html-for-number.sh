#!/usr/bin/env bash

set -euo pipefail

function usage() {
  cat <<EOF 1>&2
Usage: $0 -c <category> -n <name> [-s <season-num>] <url>...

  -u   URL from which to read
  -s   CSS selector for the element holding the value
  -n   name of the item
  -t   threshold value below which to alert
  -d   dry run - get and display the value, but don't push it anywhere
EOF
  exit 1
}

PUSH_GATEWAY_URL="http://pihole.tanners.joekearney.co.uk:9091"
JOB_NAME=html_scraper
INSTANCE_NAME="$(hostname):push"

function log() {
  cat <<< "$@" 1>&2;
}

while getopts "u:s:n:f:t:d" opt; do
  case "$opt" in
    u)
      url="$OPTARG"
      ;;
    s)
      selector="$OPTARG"
      ;;
    n)
      name="$OPTARG"
      ;;
    f)
      friendly_source_name="$OPTARG"
      ;;
    t)
      threshold_value="$OPTARG"
      ;;
    d)
      dry_run="yes"
      ;;
    *)
      usage
      ;;
  esac
done

function require_set() {
  for arg in "$@"; do
    if [[ "$arg" == "" ]]; then
      usage
    fi
  done
}

require_set "${url:-}" "${selector:-}" "${name:-}" "${friendly_source_name:-}"

function readValueFromUrl() {
  local value trimmed_value parsed_value

  value=$(curl -s "$url" | \
    pup --charset utf8 "${selector} text{}")

  trimmed_value=$(echo "${value}" | \
    sed -E 's/[^0-9]*([0-9]+.*)/\1/' | \
    sed -E 's/(.*[0-9]+)[^0-9]*/\1/' | \
    tr -cd "[^0-9.,]" | \
    sed -E 's/,([0-9][0-9])/.\1/')

  parsed_value="$(echo "${trimmed_value}" | bc)"

  log "Parsed: [${value}] -> [${trimmed_value}] -> [${parsed_value}] for [${name}] from [${friendly_source_name}]"
  echo "${parsed_value}"
}

function prometheusPushPayload() {
  local value="$1"

  local labels="name=\"$name\", friendly_source_name=\"$friendly_source_name\", url=\"$url\""

  cat <<EOF
# TYPE html_scrape_value gauge
# HELP html_scrape_value Value scraped from a website
html_scrape_value{${labels}} $value
EOF

  if [[ "${threshold_value}" != "" ]]; then
    cat <<EOF
# TYPE html_scrape_value_threshold gauge
# HELP html_scrape_value_threshold Threshold such that when html_scrape_value falls below this value an alert should be raised
html_scrape_value_threshold{${labels}} $threshold_value
EOF
  fi
}

function writeToPushGateway() {
  curl --data-binary @- \
    "${PUSH_GATEWAY_URL}/metrics/job/${JOB_NAME}/instance/${INSTANCE_NAME}"
}

VALUE="$(readValueFromUrl "${url}")"

if [[ "${dry_run:-no}" != "yes" && "${VALUE}" != "" ]]; then
  prometheusPushPayload "${VALUE}" | writeToPushGateway
  log "Pushed metric value [${VALUE}]"
fi
