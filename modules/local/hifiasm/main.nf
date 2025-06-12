process HIFIASM {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.25.0--h5ca1c30_0' :
        'biocontainers/hifiasm:0.25.0--h5ca1c30_0' }"

    input:
    tuple val(meta) , path(long_reads), path(ul_reads)
    val assembly_mode

    output:
    tuple val(meta), path("*.r_utg.gfa")                                            , emit: raw_unitigs
    tuple val(meta), path("*.bin")                                                  , emit: bin_files        , optional: true
    tuple val(meta), path("*.p_utg.gfa")                                            , emit: processed_unitigs, optional: true
    tuple val(meta), path("${prefix}.{p_ctg,bp.p_ctg,hic.p_ctg}.gfa")               , emit: primary_contigs  , optional: true
    tuple val(meta), path("${prefix}.{a_ctg,hic.a_ctg}.gfa")                        , emit: alternate_contigs, optional: true
    tuple val(meta), path("${prefix}.*.hap1.p_ctg.gfa")                             , emit: hap1_contigs     , optional: true
    tuple val(meta), path("${prefix}.*.hap2.p_ctg.gfa")                             , emit: hap2_contigs     , optional: true
    tuple val(meta), path("*.ec.fa.gz")                                             , emit: corrected_reads  , optional: true
    tuple val(meta), path("*.ovlp.paf.gz")                                          , emit: read_overlaps    , optional: true
    tuple val(meta), path("${prefix}.stderr.log")                                   , emit: log
    tuple val("${task.process}"), val('hifiasm'), eval('hifiasm --version'),   topic: versions


    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    def long_reads_sorted = long_reads instanceof List ? long_reads.sort{ it.name } : long_reads
    def ul_reads_sorted = ul_reads instanceof List ? ul_reads.sort{ it.name } : ul_reads
    def ultralong = ul_reads ? "--ul ${ul_reads_sorted}" : ""

    /*
    if( hic_reads && !(hic_reads instanceof List) ) {
        error "HIC reads must be a list"
    }
    def hic_args = hic_reads ? "--h1 ${hic_reads[0]} --h2 ${hic_reads[1]}" : ""
    */

    // Note: "Hifiasm purges haplotig duplications by default.
    // For inbred or homozygous genomes, you may disable purging with option -l0"
    def haplotig_purging_args = assembly_mode == "haplotype" ? "-l0": ""
    """
    hifiasm \\
        -l0 \\
        $args \\
        $haplotig_purging_args \\
        -t ${task.cpus} \\
        ${ultralong} \\
        -o ${prefix} \\
        ${long_reads_sorted} \\
        2>| >( tee ${prefix}.stderr.log >&2 )

    if [ -f ${prefix}.ec.fa ]; then
        gzip ${prefix}.ec.fa
    fi

    if [ -f ${prefix}.ovlp.paf ]; then
        gzip ${prefix}.ovlp.paf
    fi
    """

}
