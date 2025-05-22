
workflow ASSEMBLY {

    take:
    ch_reads

    main:

    if ( params.skip_assembly ) {
        if ( !params.assembly_fasta ) {
            error( "When setting --skip_assembly, you must also provide an assembly with --assembly_fasta" )
        } else {
            Channel.fromPath(params.assembly_fasta, checkIfExists: true)
                    .map {
                        fasta_file ->
                            def meta = [ id: fasta_file.getBaseName() ]
                            [ meta, fasta_file ]
                    }
                    .set { ch_assembly_fasta }
        }

    } else {
        PECAT_ASSEMBLY ( ch_reads )
        ch_assembly_fasta = PECAT_ASSEMBLY.out.assembly_fasta
    }

    if (params.quast) {

        MAP_TO_ASSEMBLY( ch_reads, ch_assembly )
        MAP_TO_ASSEMBLY.out.aln_to_assembly_bam.set { ch_assembly_bam }

        RUN_QUAST( ch_assembly, ch_assembly_bam )
        RUN_QUAST.out.quast_tsv.set { assembly_quast_reports }

    }

    /*
    QC on initial assembly
    */
    if (params.busco) {
        RUN_BUSCO(ch_assembly)
        RUN_BUSCO.out.batch_summary.set { assembly_busco_reports }
    }


    emit:
    assembly_fasta = ch_assembly_fasta


}
