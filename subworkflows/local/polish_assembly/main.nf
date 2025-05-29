include { RACON_POLISH  as RACON_POLISH_ROUND_1    } from '../racon_polish/main'
include { RACON_POLISH  as RACON_POLISH_ROUND_2    } from '../racon_polish/main'
include { RACON_POLISH  as RACON_POLISH_ROUND_3    } from '../racon_polish/main'
include { RACON_POLISH  as RACON_POLISH_ROUND_4    } from '../racon_polish/main'
include { RACON_POLISH  as RACON_POLISH_ROUND_5    } from '../racon_polish/main'
include { MEDAKA                                   } from '../../../modules/local/medaka/main'


workflow POLISH_ASSEMBLY {

    take:
    ch_reads
    ch_assemblies

    main:

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    if ( params.nb_racon_rounds > 0 ) {
        RACON_POLISH_ROUND_1 ( ch_reads, ch_assemblies, 1 )
        ch_assemblies = RACON_POLISH_ROUND_1.out.assemblies

        if ( params.nb_racon_rounds > 1 ) {
            RACON_POLISH_ROUND_2 ( ch_reads, ch_assemblies, 2 )
            ch_assemblies = RACON_POLISH_ROUND_2.out.assemblies

            if ( params.nb_racon_rounds > 2 ) {
                RACON_POLISH_ROUND_3 ( ch_reads, ch_assemblies, 3 )
                ch_assemblies = RACON_POLISH_ROUND_3.out.assemblies

                if ( params.nb_racon_rounds > 3 ) {
                    RACON_POLISH_ROUND_4 ( ch_reads, ch_assemblies, 4 )
                    ch_assemblies = RACON_POLISH_ROUND_4.out.assemblies

                    if ( params.nb_racon_rounds > 4 ) {
                        RACON_POLISH_ROUND_5 ( ch_reads, ch_assemblies, 5 )
                        ch_assemblies = RACON_POLISH_ROUND_5.out.assemblies
                    }
                }
            }
        }
    }

    ch_reads
        .join( ch_assemblies )
        .set { ch_medaka_input }

    MEDAKA ( ch_medaka_input )


    emit:
    assemblies = MEDAKA.out.assembly

}

