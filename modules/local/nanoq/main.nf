process NANOQ {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ee/ee6ebe971333aefe89709b6b37e62a799181be296625e4a17fa21be55a11f827/data' :
        'community.wave.seqera.io/library/nanoq_pandas:19335bf5baeeeb9c'}"

    input:
    tuple val(meta), path(ontreads)

    output:
    path("*_nanoq_summary.tsv"),                                                                                            topic: mqc_nanoq_report
    tuple val(meta), eval("cat *_nanoq_summary.tsv | tail -n 1 | tr -s ' ' | cut -d' ' -f8"),                               topic: mean_qualities
    tuple val("${task.process}"), val('python'),       eval("python3 --version | sed 's/Python //'"),                       topic: versions
    tuple val("${task.process}"), val('pandas'),       eval('python3 -c "import pandas; print(pandas.__version__)"'),       topic: versions
    tuple val("${task.process}"), val('nanoq'), eval('nanoq --version | sed -e "s/nanoq //g"'),                             topic: versions


    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_filtered"
    """
    nanoq -i $ontreads \\
        ${args} \\
        --stats \\
        --header \\
        > report.txt

    format_nanoq_report.py \\
        --report report.txt \\
        --name ${meta.id} \\
        --out ${prefix}_nanoq_summary.tsv
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}_filtered"
    """
    touch ${prefix}_nanoq_summary.tsv
    """
}
