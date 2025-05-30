process SAMTOOLS_FAIDX {
    tag "$fasta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/76/76e8e7baacbb86bca8f27e669a29a191b533bc1c5d7b08813cac7c20fcff174b/data' :
        'community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path ("*.fai"),                                                                           emit: fai
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | awk "{print $2}"'),    topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    zcat $fasta > assembly.fasta
    samtools \\
        faidx \\
        assembly.fasta \\
        $args

    """

    stub:
    def match = (task.ext.args =~ /-o(?:utput)?\s(.*)\s?/).findAll()
    def fastacmd = match[0] ? "touch ${match[0][1]}" : ''
    def get_sizes_command = get_sizes ? "touch ${fasta}.sizes" : ''
    """
    ${fastacmd}
    touch ${fasta}.fai
    if [[ "${fasta.extension}" == "gz" ]]; then
        touch ${fasta}.gzi
    fi
    """
}
