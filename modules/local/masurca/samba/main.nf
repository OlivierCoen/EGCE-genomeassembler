process MASURCA_SAMBA {
    tag "${fasta.baseName}"
    label 'process_high'

    container "quay.io/ocoen/samba:4.1.4"

    input:
    tuple val(meta), path(fasta), path(reads)

    output:
    tuple val(meta), path("*.scaffolds.fa.gz") ,                                            emit: scaffolds_fasta
    tuple val("${task.process}"), val('masurca'), val('4.1.4'),                             topic: versions
    tuple val("${task.process}"), val('pigz'), eval('pigz --version | sed "s/pigz //g"'),   topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    pigz -dkf $fasta
    reference=\$(basename $fasta .gz)

    pigz -dkf $reads
    long_reads=\$(basename $reads .gz)

    samba.sh \\
        -d ont \\
        -r \$reference \\
        -q \$long_reads

    pigz *.scaffolds.fa
    """

    stub:
    """
    touch ${prefix}..scaffolds.fa.gz
    """
}
