#!/usr/bin/env bash

mkdir -p $POD5_DIR
ont_folder_names=$(ls . | grep Clop)

for ont_folder_name in $ont_folder_names; do
    echo "Processing $ont_folder_name"
    find $ont_folder_name -type f -name "*.pod5" -exec ln -s "$(readlink -f "{}")" $POD5_DIR \;
done
