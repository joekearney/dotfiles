#!/bin/bash

set -eufo pipefail

sudo apt-get update && \
  sudo apt-get -y install \
    htop tree ncdu watch
