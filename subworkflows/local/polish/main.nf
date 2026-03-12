include { MEDAKA_WORKFLOW                     } from '../medaka'
include { ASSEMBLY_STATS                       } from '../../../modules/local/assembly_stats'


workflow POLISH {

    take:
    ch_reads
    ch_assemblies

    main:

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    ch_polished_assembly_versions = channel.empty()
    ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )

    if ( !params.skip_medaka ) {

        MEDAKA_WORKFLOW ( ch_reads, ch_assemblies )
        ch_assemblies                 = MEDAKA_WORKFLOW.out.assembly
        ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )
    }

    ASSEMBLY_STATS ( ch_assemblies )

    emit:
    assemblies                  = ch_assemblies
    polished_assembly_versions  = ch_polished_assembly_versions
}
