#!/usr/bin/env bash

# Written by Olivier Coen. Released under the MIT license.

set -euo pipefail

# parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        --report)
            report_file="$2"
            shift 2
            ;;
        --type)
            report_type="$2"
            shift 2
            ;;
        --name)
            assembly_name="$2"
            shift 2
            ;;
        --out)
            output_file="$2"
            shift 2
            ;;
        *)
            echo "Argument inconnu: $1"
            exit 1
            ;;
    esac
done

if [[ -z "${report_file:-}" || -z "${report_type:-}" || -z "${assembly_name:-}" || -z "${output_file:-}" ]]; then
    echo "Usage: $0 --report <report_file> --type <contig|assembly> --name <assembly_name> --out <output_file>"
    exit 1
fi

COLS=("unique_kmers" "total_kmers" "qv" "error_rate")

# making header
header="$report_type"
for col in "${COLS[@]}"; do
    header+="\t$col"
done

# write header
printf "%b\n" "$header" > "$output_file"

# filling with data
awk -v prefix="$assembly_name" 'BEGIN { OFS="\t" } { print prefix, $0 }' "$report_file" >> "$output_file"
