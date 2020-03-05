#!/usr/local/bin/bash

source ./yaml.sh
parse_yaml config.yml
eval $(parse_yaml config.yml)

export -p
echo "current shell test"
echo ${jail_test_pkgs}
./jailcreate.sh
