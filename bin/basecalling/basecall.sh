#!/bin/bash

current_date=$(date +"%Y%m%d_%H%M%S")
output_file="calls_${current_date}.bam"
log_file="log_${current_date}.txt"

# MODEL must be in the form {fast,hac,sup}@v{version}
# example: sup@5.2.0

dorado basecaller \
    --trim adapters \
    --emit-fastq \
    --models-directory ~/dorado-${DORADO_VERSION}-linux-x64/models \
    --recursive \
    $MODEL \
    $POD5_DIR \
    > $output_file \
    2> $log_file

# for testing, add: --max-reads 100

# samtools fastq -T '*' out.raw.bam > out.raw.fastq
