#!/bin/bash

set -e -x

sudo apt update

./install-prompt.sh
./create-swap.sh
./install-docker.sh
./install-remna-node.sh

