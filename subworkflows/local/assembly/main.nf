include { PECAT_ASSEMBLY          } from '../pecat_assembly/main'
include { MAP_TO_ASSEMBLY         } from '../map_to_assembly/main'
include { QC_QUAST               } from '../qc/quast/main'
include { QC_BUSCO               } from '../qc/busco/main'


workflow ASSEMBLY {

    take:
    ch_reads

    main:

    assembly_quast_reports = Channel.empty()
    assembly_busco_reports = Channel.empty()

    if ( !params.skip_assembly ) {

        PECAT_ASSEMBLY ( ch_reads )

        PECAT_ASSEMBLY.out.primary_assembly
            .concat( PECAT_ASSEMBLY.out.alternate_assembly )
            .concat( PECAT_ASSEMBLY.out.haplotype_1_assembly )
            .concat( PECAT_ASSEMBLY.out.haplotype_2_assembly )
            .concat( PECAT_ASSEMBLY.out.rest_first_assembly )
            .concat( PECAT_ASSEMBLY.out.rest_second_assembly )
            .set { ch_assemblies }

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
                    .set { ch_assemblies }
        }

    }

    if ( !params.skip_quast ) {

        MAP_TO_ASSEMBLY( ch_reads, ch_assemblies )

        QC_QUAST( MAP_TO_ASSEMBLY.out.aln_to_assembly_bam_ref )
        QC_QUAST.out.quast_tsv.set { assembly_quast_reports }

    }

    /*
    QC on initial assembly
    */
    if ( !params.skip_busco ) {
        QC_BUSCO( ch_assemblies )
        QC_BUSCO.out.batch_summary.set { assembly_busco_reports }
    }

    emit:
    primary_assembly = PECAT_ASSEMBLY.out.primary_assembly
    assembly_quast_reports
    assembly_busco_reports

}
