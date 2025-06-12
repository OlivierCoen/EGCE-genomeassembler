#!/usr/bin/env python3

# Written by Olivier Coen. Released under the MIT license.

import argparse
from Bio import SeqIO
import pandas as pd
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Get distributions of contig sizes given a list of Fasta files"
    )
    parser.add_argument(
        "--fasta", type=Path, required=True, dest="fasta_file", help="Input fasta file"
    )
    parser.add_argument(
        "--out", type=Path, dest="output_file", required=True, help="Path to output file"
    )
    return parser.parse_args()


def get_contig_sizes(fasta_file: Path):
    contig_sizes = []
    with open(fasta_file, 'r') as fin:
        for record in SeqIO.parse(fin, "fasta"):
            contig_sizes.append(len(record))
    return sorted(contig_sizes, reverse=True)



if __name__ == "__main__":

    args = parse_args()

    fasta_file = args.fasta_file
    df = pd.DataFrame( { fasta_file.stem: get_contig_sizes( fasta_file ) } )

    df = df.T # transpose
    df.to_csv(args.output_file, sep='\t', index=True, header=False)
    logger.info('Done')
