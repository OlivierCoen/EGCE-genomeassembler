process PEPPER_MARGIN_DEEPVARIANT {
    tag "$meta.id"
    label 'process_high'

    /*
    if (params.deepvariant_gpu) {
        container 'docker.io/kishwars/pepper_deepvariant:r0.8-gpu'
    } else {
        container 'docker.io/kishwars/pepper_deepvariant:r0.8'
    }
    */

    container 'docker.io/kishwars/pepper_deepvariant:r0.8'

    input:
    tuple val(meta), path(bam), path(index), path(fasta), path(fai)

    output:
    tuple val(meta), path("*vcf.gz")    ,  emit: vcf
    tuple val(meta), path("*vcf.gz.tbi"),  emit: tbi
    tuple val("${task.process}"), val('pepper_margin_deepvariant'), eval('run_pepper_margin_deepvariant --version | sed "s/VERSION: //g"'), topic: versions

    script:
    def args    = task.ext.args ?: ""
    def gpu     = params.deepvariant_gpu ? "-g" : ""
    prefix      = task.ext.prefix ?: "${meta.id}"
    //def regions = intervals ? "--regions ${intervals}" : ""
    //def gvcf    = params.make_gvcf ? "--gvcf" : ""
    // TODO: add $gpu arg when params.deepvariant_gpu is available
    """
    mkdir -p "${prefix}"

    run_pepper_margin_deepvariant call_variant \\
        -b "${bam}" \\
        -f "${fasta}" \\
        -o "." \\
        -p "${prefix}" \\
        -t ${task.cpus} \\
        $args
    """
}
