#!/usr/bin/env python3

# Written by Olivier Coen. Released under the MIT license.

import argparse
import pandas as pd
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(
        description="Format Quast report"
    )
    parser.add_argument(
        "--report", type=Path, required=True, dest="report_file", help="Report file"
    )
    parser.add_argument(
        "--out", type=Path, dest="output_file", required=True, help="Path to output file"
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    df = pd.read_csv(args.report_file, sep='\t')
    df = df.T # transpose
    df.to_csv(args.output_file, sep='\t', index=True, header=True)



