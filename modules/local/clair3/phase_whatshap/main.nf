process CLAIR3_PHASE_WHATSHAP {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/42/4203af0a33829ee31ac05dee3d698ae5f1e0977fc79c8ad45cbffbeb0fd8805b/data':
        'community.wave.seqera.io/library/clair3:1.1.1--394510462e5c747a' }"

    input:
    tuple val(meta), path(bam), path(bai), path(fasta), path(fai)
    val model

    output:
    tuple val(meta), path("clair3_output/merge_output.vcf.gz"),                                        emit: vcf
    tuple val(meta), path("clair3_output/merge_output.vcf.gz.tbi"),                                    emit: vcf_index
    tuple val("${task.process}"), val('clair3'), eval('run_clair3.sh --version | sed "s/Clair3 //g"'), topic: versions
    tuple val("${task.process}"), val('whatshap'), eval('whatshap --version'),                         topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if ( !meta.platform ) { error "Cannot run Clair3 without known platform" }
    def platform = meta.platform == "nanopore" ? "ont": "hifi"
    """
    zcat ${fasta} > assembly.fasta

    run_clair3.sh \\
       ${args} \\
      --bam_fn ${bam} \\
      --ref_fn assembly.fasta \\
      --threads ${task.cpus} \\
      --platform ${platform} \\
      --output clair3_output/ \\
      --model_path \$(dirname \$(which run_clair3.sh))/models/${model}/ \\
      --include_all_ctgs \\
      --use_whatshap_for_final_output_phasing

    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf
    touch ${prefix}.vcf.tbi
    """
}
