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
        description="Format Nanoq report"
    )
    parser.add_argument(
        "--report", type=Path, required=True, dest="report_file", help="Report file"
    )
    parser.add_argument(
        "--name", type=str, required=True, dest="assembly_name", help="Name of assembly"
    )
    parser.add_argument(
        "--out", type=Path, dest="output_file", required=True, help="Path to output file"
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    df = pd.read_csv(args.report_file, sep=' ')
    df.insert(0, "assembly_name", args.assembly_name)
    df.to_csv(args.output_file, index=False, sep='\t', header=True)



