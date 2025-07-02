# HI-C test data

Total reads were obtained from SRA's SRR22354810 run using sra tools.

Reference genome was obtained from [nf-core/genomeassembler test data](https://github.com/nf-core/test-datasets/blob/genomeassembler/A_thaliana_Col-0_2mb/Col-CEN_v1.2.Chr1_5MB-7MB.fasta.gz)
Reads were mapped separately against [Col-CEN_v1.2.Chr1_5MB-7MB.fasta](../../reference/a_thaliana/Col-CEN_v1.2.Chr1_5MB-7MB.fasta) uisng Bwa-MEM2 (default parameters).

SAM files were separately processed as follows:
```bash
samtools view -b -o <all.bam> <in.sam>
samtools sort -@ 12 <all.sorted.bam> <all.bam>
# separating mapped and unmapped reads
samtools view -b -F 4 -o <mapped.bam> <all.sorted.bam>
samtools view -b -f 4 -o <unmapped.bam> <all.sorted.bam>
# subsampling reads: sampling fraction were chosen according to % of mapped reads
samtools view -b -s 0.04 -o <mapped.sampled.bam> <mapped.bam>
samtools view -b -s 0.0001 -o <unmapped.sampled.bam> <unmapped.bam>
# merging
samtools merge <merged.bam> <mapped.sampled.bam> <unmapped.sampled.bam>
# make FASTQ files out of BAM files
samtools fastq --reference Col-CEN_v1.2.Chr1_5MB-7MB.fasta <merged.bam> | gzip -n > <fastq file>
```
