include { PECAT_ASSEMBLY          } from '../pecat_assembly/main'
include { POLISH_ASSEMBLY         } from '../polish_assembly/main'
include { QC_ASSEMBLIES           } from '../qc_assemblies/main'

include { FLYE                    } from '../../../modules/nf-core/flye/main'


workflow ASSEMBLY {

    take:
    ch_reads

    main:
    ch_versions = Channel.empty()
    assembly_quast_reports = Channel.empty()
    assembly_busco_reports = Channel.empty()

    // --------------------------------------------------------
    // Primary Assembly
    // --------------------------------------------------------

    if ( params.skip_assembly ) {

        if ( !params.assembly_fasta ) {
            error( "When setting --skip_assembly, you must also provide an assembly with --assembly_fasta" )
        } else {
            Channel.fromPath(params.assembly_fasta, checkIfExists: true)
                    .map {
                        fasta_file ->
                            def meta = [
                                id: fasta_file.getBaseName(),
                                genome_size: params.genome_size
                            ]
                            [ meta, fasta_file ]
                    }
                    .set { ch_assemblies }
        }

    } else {

        if ( params.assembler == "flye" ) {

            FLYE( ch_reads, params.flye_mode )
            FLYE.out.fasta.set { ch_assemblies }
            ch_versions = ch_versions.mix ( FLYE.out.versions )

        } else { //pecat

            PECAT_ASSEMBLY ( ch_reads )

            Channel.emtpy()
                .concat( PECAT_ASSEMBLY.out.primary_assembly )
                .concat( PECAT_ASSEMBLY.out.alternate_assembly )
                .concat( PECAT_ASSEMBLY.out.haplotype_1_assembly )
                .concat( PECAT_ASSEMBLY.out.haplotype_2_assembly )
                .concat( PECAT_ASSEMBLY.out.rest_first_assembly )
                .concat( PECAT_ASSEMBLY.out.rest_second_assembly )
                .set { ch_assemblies }
        }

    }

    // --------------------------------------------------------
    // Polishing
    // --------------------------------------------------------

    if ( params.assembler == "flye" ) {

         if ( !params.skip_polishing ) {
            POLISH_ASSEMBLY ( ch_reads, ch_assemblies )
            POLISH_ASSEMBLY.out.assemblies.set { ch_assemblies }
         }

    }

    // --------------------------------------------------------
    // Quality Control
    // --------------------------------------------------------

    QC_ASSEMBLIES ( ch_reads, ch_assemblies )
    ch_versions = ch_versions.mix ( QC_ASSEMBLIES.out.versions )

    emit:
    assemblies = ch_assemblies
    assembly_quast_reports = QC_ASSEMBLIES.out.assembly_quast_reports
    assembly_busco_reports = QC_ASSEMBLIES.out.assembly_busco_reports
    assembly_merqury_reports = QC_ASSEMBLIES.out.assembly_merqury_reports
    versions = ch_versions                     // channel: [ versions.yml ]

}

def addPecatAssemblyType( ch_assembly ) {
    return ch_assembly.map { meta, assembly -> [ meta + [ type: assembly.simpleName ], assembly ] }
}
