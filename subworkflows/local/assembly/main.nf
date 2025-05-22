include { PECAT_ASSEMBLY          } from '../pecat_assembly/main'
include { MAP_TO_ASSEMBLY         } from '../map_to_assembly/main'
include { QC_QUAST               } from '../qc/quast/main'
include { QC_BUSCO               } from '../qc/busco/main'


workflow ASSEMBLY {

    take:
    ch_reads

    main:

    if ( !params.skip_assembly ) {

        PECAT_ASSEMBLY ( ch_reads )
        ch_assembly_fasta = PECAT_ASSEMBLY.out.assembly_fasta

    } else {

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

    }

    if ( !params.skip_quast ) {

        MAP_TO_ASSEMBLY( ch_reads, ch_assembly_fasta )
        MAP_TO_ASSEMBLY.out.aln_to_assembly_bam.set { ch_assembly_bam }

        QC_QUAST( ch_assembly_fasta, ch_assembly_bam )
        QC_QUAST.out.quast_tsv.set { assembly_quast_reports }

    }

    /*
    QC on initial assembly
    */
    if ( !params.skip_busco ) {
        QC_BUSCO( ch_assembly_fasta )
        QC_BUSCO.out.batch_summary.set { assembly_busco_reports }
    }


    emit:
    assembly_fasta = ch_assembly_fasta


}
