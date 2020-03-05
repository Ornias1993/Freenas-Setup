#!/usr/local/bin/bash

source ./yaml.sh
eval $(parse_yaml config.yml)


./jailcreate.sh test5
