#!/usr/bin/env python3

# Written by Olivier Coen. Released under the MIT license.

import sys
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

STEP_TO_ARGS = {
    "correct": [
        "prep_min_length",
        "prep_output_coverage",
        "corr_iterate_number",
        "corr_block_size",
        "corr_filter_options",
        "corr_correct_options",
        "corr_rd2rd_options",
        "corr_output_coverage"
    ],
    "first_assembly": [
        "align_block_size",
        "align_rd2rd_options",
        "align_filter_options",
        "asm1_assemble_options"
    ],
    "phase": [
        "phase_method",
        "phase_rd2ctg_options",
        "phase_phase_options",
        "phase_use_reads",
        "phase_filter_options",
        "phase_clair3_rd2ctg_options",
        "phase_clair3_phase_options",
        "phase_clair3_use_reads",
        "phase_clair3_filter_options"
    ],
    "second_assembly": [
        "asm2_assemble_options"
    ],
    "polish": [
        "polish_map_options",
        "polish_use_reads",
        "polish_cns_options",
        "polish_medaka_map_options",
        "polish_medaka_cns_options"
    ]
}


def parse_config_file(file_path):
    config = {}
    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, value = line.split('=', 1)
                config[key.strip()] = value.strip()
    return config


if __name__ == "__main__":

    logger.info(f"Splitting step-specific configs")
    logger.info(f"Reading config file")
    config_file = sys.argv[1]
    config = parse_config_file(config_file)

    for step, step_args in STEP_TO_ARGS.items():
        output_file = Path(config_file).parent / f"{step}.cfgfile"
        with open(output_file, "w") as fout:
            for arg in step_args:
                if arg in config:
                    line = f"{arg} = {config[arg]}\n"
                    fout.write(line)

