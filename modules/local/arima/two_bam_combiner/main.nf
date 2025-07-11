process ARIMA_TWO_BAM_COMBINER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/2b/2b7cff481d8ae8d8e9b3eaceee4beb8bd95e1d7ad21f26de007be0a72f3abbed/data':
        'community.wave.seqera.io/library/samtools_perl:57518a456f66aec6' }"

    input:
    tuple val(meta), path(r1_bam, stageAs: "*/*"), path(r2_bam, stageAs: "*/*")
    tuple val(meta2), path(reference_genome_index)
    val mapq_filter

    output:
    tuple val(meta), path("*.combined.bam"),         emit: bam
    tuple val("${task.process}"), val('perl'), val('5.32.1'),                                                  topic: versions
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | awk "{print $2}"'),    topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    two_read_bam_combiner.pl $r1_bam $r2_bam 'samtools' $mapq_filter \
        | samtools view -bS -t $reference_genome_index - \
        | samtools sort -@ ${task.cpus} -o ${prefix}.combined.bam -

    """
}
