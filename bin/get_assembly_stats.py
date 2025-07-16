#!/usr/bin/env python
import argparse
from Bio import SeqIO


def parse_args():
    parser = argparse.ArgumentParser(description="Compute assembly stats for a fasta file")
    parser.add_argument("--fasta", type=str, required=True)
    return parser.parse_args()


def get_contig_lengths(assembly_file: str):
    lengths = [len(record.seq) for record in SeqIO.parse(assembly_file, "fasta")]
    return sorted(lengths, reverse=True)


def calculate_nx_stats(lengths):
    total_length = sum(lengths)
    nx_stats = {}
    for n in range(50, 100):
        cumulative_length = 0
        for i, length in enumerate(lengths):
            cumulative_length += length
            if cumulative_length >= total_length * n / 100:
                nx_stats[n] = dict(N=length, L=i+1)
                break
    return nx_stats


if __name__ == "__main__":
    args = parse_args()
    contig_lengths = get_contig_lengths(args.fasta)
    nx_stats = calculate_nx_stats(contig_lengths)
    for n, stats in nx_stats.items():
        print(f"N{n}: {stats['N']} | L{n}: {stats['L']}")
