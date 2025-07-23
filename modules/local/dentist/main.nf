process DENTIST {
    tag "$meta.id"
    label 'process_high_cpu'
    label 'process_high_memory'
    label 'process_long'

    //container "quay.io/ocoen/dentist:4.0.0"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ca/cae3ab57e8f3ffee7165068ad77b0814b210743767eff3d02db323fe528a4843/data' :
        'community.wave.seqera.io/library/dentist-core_snakemake:dada80c0e4030069' }"

    input:
    tuple val(meta), path(reads_fasta), path(assembly)

    output:
    tuple val(meta), path("*.fasta.gz"),                                                                    emit: fasta
    tuple val("${task.process}"), val('dentist'), eval("dentist --version 2>&1 | awk '{print \$2; exit}'"), topic: versions
    tuple val("${task.process}"), val('snakemake'), eval("snakemake --version"),                            topic: versions
    tuple val("${task.process}"), val('pigz'), eval('pigz --version | sed "s/pigz //g"'),                   topic: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${assembly.baseName}_gapclosed"
    def use_frontend_arg = workflow.profile.tokenize(',').intersect(['conda']).size() >= 1 ? "--conda-frontend=conda" : ""
    def platform = meta.platform == "nanopore" ? "OXFORD_NANOPORE": "PACBIO_SMRT"
    """
    pigz -dkf $fasta
    reference=\$(basename $fasta .gz)

    pigz -dkf $reads
    long_reads=\$(basename $reads .gz)

    # Writing config files
    cat <<EOF > snakemake.yml
    dentist_config:         dentist.yml
    inputs:
        reference:          \$reference
        reads:              \$long_reads
        reads_type:         $platform
    outputs:
        output_assembly:    ${prefix}.fasta
    reference_dbsplit:
        - -x1000
        - -a
        - -s200
    reads_dbsplit:
        - -x1000
        - -a
        - -s200
    workdir:            workdir
    logdir:             logs
    threads_per_process:  8
    propagate_batch_size: 50
    batch_size:         50
    validation_blocks:  32
    EOF




    snakemake \\
         --use-conda \\
         --configfile=snakemake.yml \\
         --cores=${task.cpus} \\
         $use_frontend_arg
    """

}
