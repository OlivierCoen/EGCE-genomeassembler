include { ASSEMBLY                             } from '../assembly/main'
include { POLISH_ASSEMBLY                      } from '../polish_assembly/main'
include { QC_ASSEMBLIES                        } from '../qc_assemblies/main'


workflow ASSEMBLY_POLISH_QC {

    take:
    ch_reads_to_assemble
    ch_reads_assembled
    ch_assemblies

    main:
    ch_versions = Channel.empty()


    // --------------------------------------------------------
    // Primary Assembly
    // --------------------------------------------------------

    ASSEMBLY ( ch_reads_to_assemble )

    ch_reads_to_assemble
        .mix ( ch_reads_assembled )
        .set { ch_reads }

    ch_assemblies
        .mix ( ASSEMBLY.out.assemblies )
        .set { ch_assemblies }

    // --------------------------------------------------------
    // POLISHING
    // --------------------------------------------------------

    if ( params.assembler == "flye" ) {

        // we do not need to filter reads for now
        // because reads and assemblies are combined during the map_to_assembly subworkflows
        ch_assemblies
            .branch { meta, assembly ->
                polish_me: meta.polish_draft_assembly
                leave_me_alone: !meta.polish_draft_assembly
            }
            .set { ch_assemblies }

        POLISH_ASSEMBLY ( ch_reads, ch_assemblies.polish_me )

        ch_assemblies.leave_me_alone
            .mix ( POLISH_ASSEMBLY.out.polished_assembly_versions )
            .set { ch_draft_assembly_versions }

        ch_assemblies.leave_me_alone
            .mix ( POLISH_ASSEMBLY.out.assemblies )
            .set { ch_assemblies }

    }

    // --------------------------------------------------------
    // QUALITY CONTROL
    // --------------------------------------------------------

    QC_ASSEMBLIES ( ch_reads, ch_draft_assembly_versions ) // QC on all versions of the polishing, to see the evolution

    ch_versions = ch_versions
                    .mix ( ASSEMBLY.out.versions )
                    .mix ( POLISH_ASSEMBLY.out.versions )
                    .mix ( QC_ASSEMBLIES.out.versions )

    emit:
    assemblies                       = ch_assemblies
    flye_report                      = ASSEMBLY.out.flye_report
    assembly_busco_reports           = QC_ASSEMBLIES.out.assembly_busco_reports
    versions                         = ch_versions                     // channel: [ versions.yml ]

}
