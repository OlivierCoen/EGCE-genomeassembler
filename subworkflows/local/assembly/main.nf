include { PECAT_ASSEMBLY          } from '../pecat_assembly/main'
include { QC_ASSEMBLIES           } from '../qc_assemblies/main'


workflow ASSEMBLY {

    take:
    ch_reads

    main:
    ch_versions = Channel.empty()
    assembly_quast_reports = Channel.empty()
    assembly_busco_reports = Channel.empty()

    if ( !params.skip_assembly ) {

        if ( params.assembler == "flye" ) {
            println "ok"
        } else { //pecat

            PECAT_ASSEMBLY ( ch_reads )

            PECAT_ASSEMBLY.out.primary_assembly
                .concat( PECAT_ASSEMBLY.out.alternate_assembly )
                .concat( PECAT_ASSEMBLY.out.haplotype_1_assembly )
                .concat( PECAT_ASSEMBLY.out.haplotype_2_assembly )
                .concat( PECAT_ASSEMBLY.out.rest_first_assembly )
                .concat( PECAT_ASSEMBLY.out.rest_second_assembly )
                .set { ch_assemblies }
        }

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

    QC_ASSEMBLIES (
        ch_reads,
        ch_assemblies
    )

    emit:
    primary_assembly = PECAT_ASSEMBLY.out.primary_assembly
    assembly_quast_reports = QC_ASSEMBLIES.out.assembly_quast_reports
    assembly_busco_reports = QC_ASSEMBLIES.out.assembly_busco_reports
    assembly_merqury_reports = QC_ASSEMBLIES.out.assembly_merqury_reports
    versions = ch_versions                     // channel: [ versions.yml ]

}
