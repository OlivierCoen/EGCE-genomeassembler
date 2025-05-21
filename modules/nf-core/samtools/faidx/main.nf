process SAMTOOLS_FAIDX {
    tag "$fasta"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/76/76e8e7baacbb86bca8f27e669a29a191b533bc1c5d7b08813cac7c20fcff174b/data' :
        'community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c' }"

    input:
    tuple val(meta), path(fasta)
    val get_sizes

    output:
    tuple val(meta), path ("*.{fa,fasta}") , emit: fa, optional: true
    tuple val(meta), path ("*.sizes")      , emit: sizes, optional: true
    tuple val(meta), path ("*.fai")        , emit: fai, optional: true
    tuple val(meta), path ("*.gzi")        , emit: gzi, optional: true
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def get_sizes_command = get_sizes ? "cut -f 1,2 ${fasta}.fai > ${fasta}.sizes" : ''
    """
    samtools \\
        faidx \\
        $fasta \\
        $args

    ${get_sizes_command}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
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

    ${get_sizes_command}

    cat <<-END_VERSIONS > versions.yml

    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
