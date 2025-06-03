include { RACON_WORKFLOW  as RACON_ROUND_1    } from '../racon/main'
include { RACON_WORKFLOW  as RACON_ROUND_2    } from '../racon/main'
include { RACON_WORKFLOW  as RACON_ROUND_3    } from '../racon/main'
include { RACON_WORKFLOW  as RACON_ROUND_4    } from '../racon/main'
include { RACON_WORKFLOW as  RACON_ROUND_5    } from '../racon/main'

include { MEDAKA                      } from '../../../modules/local/medaka'


workflow POLISH {

    take:
    ch_reads
    ch_assemblies

    main:

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    ch_polished_assembly_versions = Channel.empty()
    ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )

    if ( params.nb_racon_rounds > 0 ) {
        RACON_ROUND_1 ( ch_reads, ch_assemblies, 1 )
        ch_assemblies = RACON_ROUND_1.out.assemblies
        ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )

        if ( params.nb_racon_rounds > 1 ) {
            RACON_ROUND_2 ( ch_reads, ch_assemblies, 2 )
            ch_assemblies = RACON_ROUND_2.out.assemblies
            ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )

            if ( params.nb_racon_rounds > 2 ) {
                RACON_ROUND_3 ( ch_reads, ch_assemblies, 3 )
                ch_assemblies = RACON_ROUND_3.out.assemblies
                ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )

                if ( params.nb_racon_rounds > 3 ) {
                    RACON_ROUND_4 ( ch_reads, ch_assemblies, 4 )
                    ch_assemblies = RACON_ROUND_4.out.assemblies
                    ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )

                    if ( params.nb_racon_rounds > 4 ) {
                        RACON_ROUND_5 ( ch_reads, ch_assemblies, 5 )
                        ch_assemblies = RACON_ROUND_5.out.assemblies
                        ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )
                    }
                }
            }
        }
    }

    ch_reads
        .join( ch_assemblies )
        .set { ch_medaka_input }

    MEDAKA ( ch_medaka_input )
    ch_assemblies = MEDAKA.out.assembly
    ch_polished_assembly_versions = ch_polished_assembly_versions.mix ( ch_assemblies )


    emit:
    assemblies = ch_assemblies
    polished_assembly_versions = ch_polished_assembly_versions

}

