#!/bin/bash

set -e -x

sudo apt update

./create-swap.sh
./install-docker.sh
./install-remna-node.sh

