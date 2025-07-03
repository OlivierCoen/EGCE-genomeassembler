# HI-C test data

Total reads were obtained from SRA's SRR22354810 run using sra tools.

Reference genome was obtained from [nf-core/genomeassembler test data](https://github.com/nf-core/test-datasets/blob/genomeassembler/A_thaliana_Col-0_2mb/Col-CEN_v1.2.Chr1_5MB-7MB.fasta.gz)
Reads were mapped separately against [Col-CEN_v1.2.Chr1_5MB-7MB.fasta](../../reference/a_thaliana/Col-CEN_v1.2.Chr1_5MB-7MB.fasta) uisng Bwa-MEM2 (default parameters).

SAM files were separately processed as follows:
```bash
samtools sort -@ 24 --output-fmt BAM -o SRR22354810_1.sorted.bam SRR22354810_1.sam
# separating mapped and unmapped reads
samtools view -b -F 4 -o SRR22354810_1.sorted.mapped.bam SRR22354810_1.sorted.bam
samtools view -b -f 4 -o SRR22354810_1.sorted.unmapped.bam SRR22354810_1.sorted.bam
# subsampling reads: sampling fraction were chosen according to % of mapped reads
samtools view -b -s 0.04 -o SRR22354810_1.sorted.mapped.sampled.bam SRR22354810_1.sorted.mapped.bam
samtools view -b -s 0.0001 -o SRR22354810_1.sorted.unmapped.sampled.bam SRR22354810_1.sorted.unmapped.bam
# merging
samtools merge SRR22354810_1.merged.bam SRR22354810_1.sorted.mapped.sampled.bam SRR22354810_1.sorted.unmapped.sampled.bam
# sort by names
samtools sort -@ 24 -n -o SRR22354810_1.merged.sorted.bam SRR22354810_1.merged.bam
# getting IDs in mate 1 BAM
samtools view SRR22354810_1.merged.sorted.bam | cut -f1 | sort | uniq > readnames.txt
samtools view -h -N readnames.txt SRR22354810_2.sam | samtools view -bo SRR22354810_2.filtered.bam
# sort by name
samtools sort -@ 24 -n -o SRR22354810_2.filtered.sorted.bam SRR22354810_2.filtered.bam
# make FASTQ files out of BAM files
samtools fastq --reference Col-CEN_v1.2.Chr1_5MB-7MB.fasta SRR22354810_1.merged.sorted.bam > SRR22354810_1.sampled.fq
samtools fastq --reference Col-CEN_v1.2.Chr1_5MB-7MB.fasta SRR22354810_2.filtered.sorted.bam > SRR22354810_2.sampled.fq
```
samtools version used: 1.22

Since both Fastq files not ha
