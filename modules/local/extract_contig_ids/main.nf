process EXTRACT_CONTIG_IDS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/cb/cb3804ff1e384f1d12ce6b1063a95e84b155b784d9287e44d431972593e61f98/data' :
        'community.wave.seqera.io/library/pigz:2.8--79421657784d0869' }"

    input:
    tuple val(meta), path(fasta)
    val shuffle_contigs

    output:
    tuple val(meta), path("contigs.txt"),                                                   emit: contigs
    tuple val("${task.process}"), val('pigz'), eval('pigz --version | sed "s/pigz //g"'),   topic: versions

    script:

    def prefix = task.ext.prefix ?: "${meta.id}"
    def shuffle_cmd = shuffle_contigs ? "| shuf": ""
    """
    pigz -dkf $fasta
    reference=\$(basename $fasta .gz)

    grep '^>' \$reference \\
        | sed 's/^>//g' \\
        | awk '{print \$1}' \\
        $shuffle_cmd \\
        > contigs.txt

    """
}
