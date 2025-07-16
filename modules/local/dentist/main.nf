process DENTIST {
    tag "$meta.id"
    label 'process_high_cpu'
    label 'process_high_memory'
    label 'process_long'

    container "quay.io/ocoen/dentist:4.0.0"

    input:
    tuple val(meta), path(reads), val(mean_quality)

    output:
    tuple val(meta), path("*.fasta.gz"),                               emit: fasta

    tuple val("${task.process}"), val('dentist'), eval("dentist --version 2>&1 | awk '{print \$2; exit}'"), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """


    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    """
}
