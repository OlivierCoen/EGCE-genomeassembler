process CONTIG_STATS {
    tag "${fasta.simpleName}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8a/8a1927073c1364f8532fb5461146678c70aeffe35f390de2c632e25decaa4841/data' :
        'community.wave.seqera.io/library/biopython_pandas:ebd73ca158d78599' }"

    input:
    tuple val(meta), path(fasta)

    output:
    path("*_contig_sizes.tsv"),                                                                                             topic: mqc_contig_sizes

    tuple val("${task.process}"), val('python'),       eval("python3 --version | sed 's/Python //'"),                       topic: versions
    tuple val("${task.process}"), val('pandas'),       eval('python3 -c "import pandas; print(pandas.__version__)"'),       topic: versions
    tuple val("${task.process}"), val('biopython'),    eval('python3 -c "import Bio; print(Bio.__version__)"'),             topic: versions

    script:
    def prefix        = task.ext.prefix ?: "${fasta.simpleName}"
    """
    zcat -k $fasta > "${fasta.baseName}"

    get_contig_size_distributions.py \\
        --fasta ${fasta.baseName} \\
        --out ${prefix}_contig_sizes.tsv
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tsv
    """
}
