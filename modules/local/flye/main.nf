def getQScoreCategory ( mean_quality ) {
    if ( mean_quality < 7 ) {
        warning "Very low quality reads: $mean_quality"
        return "raw"
    } else if ( mean_quality >= 7 && mean_quality < 15 ) {
        return "raw"
    } else if ( mean_quality >= 15 && mean_quality < 20 ) {
        return "corr"
    } else { // mean_quality >= 20
        return "hq"
    }
}

process FLYE {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/fa/fa1c1e961de38d24cf36c424a8f4a9920ddd07b63fdb4cfa51c9e3a593c3c979/data' :
        'community.wave.seqera.io/library/flye:2.9.5--d577924c8416ccd8' }"

    input:
    tuple val(meta), path(reads), val(mean_quality)

    output:
    tuple val(meta), path("*.fasta.gz"),                               emit: fasta
    tuple val(meta), path("*.gfa.gz")  ,                               emit: gfa
    tuple val(meta), path("*.gv.gz")   ,                               emit: gv
    tuple val(meta), path("*.txt")     ,                               emit: txt
    tuple val(meta), path("*.log")     ,                               emit: log
    tuple val(meta), path("*.json")    ,                               emit: json
    tuple val("${task.process}"), val('flye'), eval('flye --version'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // flye mode
    if ( !meta.technology ) { error "Cannot run Flye without technology" }
    if ( !mean_quality ) { error "Cannot run Flye without mean quality" }
    def qscore_category = getQScoreCategory( mean_quality )
    def mode = "--${meta.technology}-${qscore_category}"
    // genome size
    def genome_size_arg = meta.genome_size ? "--genome-size ${meta.genome_size}" : ""
    """
    flye \\
        --${mode} \\
        $reads \\
        --out-dir . \\
        --threads \\
        $task.cpus \\
        $genome_size_arg \\
        $args

    gzip -c assembly.fasta > ${prefix}.assembly.fasta.gz
    gzip -c assembly_graph.gfa > ${prefix}.assembly_graph.gfa.gz
    gzip -c assembly_graph.gv > ${prefix}.assembly_graph.gv.gz
    mv assembly_info.txt ${prefix}.assembly_info.txt
    mv flye.log ${prefix}.flye.log
    mv params.json ${prefix}.params.json
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo stub | gzip -c > ${prefix}.assembly.fasta.gz
    echo stub | gzip -c > ${prefix}.assembly_graph.gfa.gz
    echo stub | gzip -c > ${prefix}.assembly_graph.gv.gz
    echo contig_1 > ${prefix}.assembly_info.txt
    echo stub > ${prefix}.flye.log
    echo stub > ${prefix}.params.json
    """
}
