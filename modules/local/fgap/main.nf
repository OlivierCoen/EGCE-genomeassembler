process FGAP {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/spec-file.txt"
    container "community.wave.seqera.io/library/fgap_pigz:d1c5fe4fb500534b"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_gapclosed*.fasta.gz"),                                                                  emit: gapclosed_assemblies
    tuple val("${task.process}"), val('fgap'), eval("FGAP --help 2>&1 | grep FGAP | grep -oP '\\d+\\.\\d+\\.\\d+'"), topic: versions
    tuple val("${task.process}"), val('pigz'), eval('pigz --version | sed "s/pigz //g"'),                            topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    if [[ $assembly == *.gz ]]; then
       pigz -dkf $assembly
       reference=\$(basename $assembly .gz)
    else
        reference=$assembly
    fi

    if [[ $reads == *.gz ]]; then
       pigz -dkf $reads
       long_reads=\$(basename $reads .gz)
    else
       long_reads=$reads
    fi

    prefix=\${reference%.*}_gapclosed

    FGAP "\\
        ${args} \\
        -d \$reference \\
        -a \$long_reads \\
        -o \$prefix \\
        -t ${task.cpus}"

    if [[ -e \${prefix}*.fasta ]]; then
        # remove unwanted parts in output file name
        mv \${prefix}*.fasta \${prefix}.fasta
        pigz \${prefix}.fasta
    else
        echo "No output found. Using existing assembly as gapclosed assembly"
        if [[ $assembly == *.gz ]]; then
            ln -s $assembly \${prefix}.fasta.gz
        else
            pigz -c $assembly > \${prefix}.fasta.gz
        fi
    fi

    # remove unwanted intermediate files
    rm -f \${prefix}_*.fasta \${prefix}.final.fasta
    """


}
