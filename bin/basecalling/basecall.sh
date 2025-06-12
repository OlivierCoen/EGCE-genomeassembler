#!/bin/bash

dorado basecaller \
    --trim adapters \
    --models-directory ~/dorado-${DORADO_VERSION}-linux-x64/models \
    --recursive \
    $MODEL \
    $POD5_DIR

# samtools fastq -T '*' out.raw.bam > out.raw.fastq
