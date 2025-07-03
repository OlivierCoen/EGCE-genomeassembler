process QUAST {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/24/245c56c9733954bbf2675e19b922d63772731d7bc7ebe6964b8119fb6a9a3a12/data' :
        'community.wave.seqera.io/library/quast_pandas:45a80fbbe1a6f7b8' }"

    input:
    tuple val(meta), path(assembly_list, stageAs: "*/*"), path(aln_long_reads_assembly_bam_list, stageAs: "*/*")


   output:
    path("${meta.id}*/*"),                                                                                                  emit: results

    path("*_quast_report.tsv"),                                                                                             topic: mqc_quast_report
    tuple val("${task.process}"), val('python'),       eval("python3 --version | sed 's/Python //'"),                       topic: versions
    tuple val("${task.process}"), val('pandas'),       eval('python3 -c "import pandas; print(pandas.__version__)"'),       topic: versions
    tuple val("${task.process}"), val('quast'), eval('quast --version | grep "QUAST" | sed "s#QUAST ##g"'),                 topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def assembly = assembly_list.join(' ')
    def bam = aln_long_reads_assembly_bam_list.join(',')

    """
    quast.py \\
        --output-dir ${prefix} \\
        --threads ${task.cpus} \\
        ${assembly} \\
        --bam ${bam} \\
        ${args}

    format_quast_report.py \\
        --report ${prefix}/report.tsv \\
        --out ${prefix}_quast_report.tsv
    """

}
