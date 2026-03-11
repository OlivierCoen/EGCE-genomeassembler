process BWAMEM2_MEM {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/9a/9ac054213e67b3c9308e409b459080bbe438f8fd6c646c351bc42887f35a42e7/data' :
        'community.wave.seqera.io/library/bwa-mem2_htslib_samtools:e1f420694f8e42bd' }"

    input:
    tuple val(meta), path(reads), path(fasta), path(fai)
    val primary_alignments_only

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val("${task.process}"), val('bwamem2'), eval("bwa-mem2 version 2>&1 | tail -1 | sed 's/.* //'"), topic: versions
    tuple val("${task.process}"), val('samtools'), eval("samtools --version | sed '1!d; s/samtools //'"),  topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: reads instanceof Path ? "${reads.simpleName}_${fasta.simpleName}" : "${fasta.simpleName}"
    def additional_alignments_flags = primary_alignments_only ? "-F 256 -F 2048" : ""
    """
    INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

    bwa-mem2 mem \\
        $args \\
        -t $task.cpus \\
        \$INDEX \\
        $reads \\
        | samtools view \\
        -Sb \\
        -F 4 \\
        $additional_alignments_flags \\
        $args2 \\
        -@ ${task.cpus} \\
        -o ${prefix}.bam -
    """
}
