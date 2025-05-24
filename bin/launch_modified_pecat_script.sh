#!/usr/bin/env bash

pecat_script_directory=$(dirname $(cat $(which pecat.pl) | grep -oP '^/\S*/pecat\.pl'))

${pecat_script_directory}/modified_pecat.pl "$@"
