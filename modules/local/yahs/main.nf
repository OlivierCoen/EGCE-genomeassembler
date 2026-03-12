process YAHS {
    tag "${fasta.simpleName}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['apptainer', 'singularity'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/e9/e9c62e34fc2b2a7a482d894cc201be6c447d7c90047dc0fd3c6210d6893cd968/data':
        'community.wave.seqera.io/library/yahs_pigz:0ea95483ff8bc79e' }"

    input:
    tuple val(meta), path(bam), path(fasta), path(fai)

    output:
    tuple val(meta), path("${prefix}_scaffolded.fa.gz") ,                                            emit: fasta
    tuple val(meta), path("${prefix}.alignments.txt"),                                               emit: alignments
    tuple val(meta), path("${prefix}.chrom_sizes.txt"),                                              emit: chrom_sizes
    tuple val("${task.process}"), val('yahs'), eval('yahs --version 2>&1'),                          topic: versions
    tuple val("${task.process}"), val('pigz'), eval('pigz --version | sed "s/pigz //g"'),            topic: versions
    tuple val("${task.process}"), val('juicer'), eval("juicer 2>&1 | grep Version | cut -d' ' -f2"), topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    prefix = task.ext.prefix ?: "${bam.baseName}_on_${fasta.baseName.tokenize(".")[0..-2].join('.')}"
    """
    pigz -dkf $fasta
    reference=\$(basename $fasta .gz)
    cp $fai "\${reference}.fai"

    echo "Running YAHS"
    yahs $args \\
        -o $prefix \\
        \$reference \\
        $bam

    pigz ${prefix}_scaffolds_final.fa
    mv ${prefix}_scaffolds_final.fa.gz ${prefix}_scaffolded.fa.gz

    echo "Running Juicer Pre"
    juicer pre \\
        ${prefix}.bin \\
        ${prefix}_scaffolds_final.agp \\
        $fai \\
        $args2 \\
        2> >(tee juicer_pre.log >&2) \\
        | LC_ALL=C sort -k2,2d -k6,6d \\
        | awk 'NF' \\
        > ${prefix}.alignments.txt

    echo "Computing chromosome sizes"
    cat juicer_pre.log \\
        | grep "PRE_C_SIZE" \\
        | cut -d' ' -f2- \\
        > ${prefix}.chrom_sizes.txt
    """
}
