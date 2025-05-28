#!/usr/bin/env python3

# Written by Olivier Coen. Released under the MIT license.

import argparse
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ------------------------------------------------------
# WRITING THE BASE CONFIGURATION IN THE CONFIG FILE
# ------------------------------------------------------
BASE_CONFIG = """
project = results
reads = {read_file}
genome_size = {genome_size}
threads = {cpus}
cleanup = 1
grid = local

"""

STEP_SPECIFIC_CONFIGS = {
    "phase": [
        "phase_clair3_command = run_clair3.sh"
    ],
    "polish": [
        "polish_medaka = 1",
        "polish_medaka_command = medaka"
    ]
}

PHASE_CLAIR3_OPTIONS = "phase_clair3_options = --platform=ont --model_path={model_path}  --include_all_ctgs"

def parse_args():
    parser = argparse.ArgumentParser(
        description="Build config file for a specific step of PECAT"
    )
    parser.add_argument(
        "--step", type=str, required=True, help="PECAT step",
        choices=["correct", "first_assembly", "phase", "second_assembly", "polish"]
    )
    parser.add_argument(
        "--config", type=Path, dest="config_file", required=True,
        help="Custom config file for this step"
    )
    parser.add_argument(
        "--reads", type=Path, dest="read_file", required=True,
        help="Path to read file"
    )
    parser.add_argument(
        "--cpus", type=int,required=True, help="Nb of CPUs"
    )
    parser.add_argument(
        "--genome-size", type=int, dest="genome_size", required=True, help="Estimated genome size"
    )
    parser.add_argument(
        "--model-path", type=Path, dest="model_path", required=False, help="Model path (for Clair3 only)"
    )
    return parser.parse_args()



if __name__ == "__main__":

    logger.info(f"Writing config file cfgfile")
    args = parse_args()

    formated_base_config = BASE_CONFIG.format(
        read_file=args.read_file,
        genome_size=args.genome_size,
        cpus=args.cpus
    )



    with open('cfgfile', "w") as fout:

        # writing base config
        fout.write(formated_base_config)

        # writing step-specific base config if any
        if args.step in STEP_SPECIFIC_CONFIGS:
            for line in STEP_SPECIFIC_CONFIGS[args.step]:
                fout.write(f'{line}\n')

        if args.step == "phase":
            if args.model_path is None:
                raise ValueError("Model path must be provided when step is phase")
            formated_phase_clair3_options_line = PHASE_CLAIR3_OPTIONS.format(model_path=args.model_path)
            fout.write(f'{formated_phase_clair3_options_line}\n')

        # writing custom config
        with open(args.config_file, 'r') as fin:
            for line in fin.readlines():
                fout.write(line)

    logger.info('Done')
