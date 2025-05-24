#!/usr/bin/env bash

echo "Getting"
pecat_script_directory=$(dirname $(cat $(which pecat.pl) | grep -oP '^/\S*/pecat\.pl'))

echo "Copying modified_pecat.pl to $pecat_script_directory"

bin_dir=$(dirname $(realpath $0))
cp ${bin_dir}/modified_pecat.pl $pecat_script_directory
