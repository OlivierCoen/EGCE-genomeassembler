include { MEDAKA                       } from '../../../modules/local/medaka/main'

workflow POLISH_ASSEMBLY {

    take:
    ch_reads
    ch_assemblies

    main:

    ch_versions = Channel.empty()

    ch_reads
        .join( ch_assemblies )
        .set { ch_medaka_input }
    MEDAKA ( ch_medaka_input )


    emit:
    assemblies = MEDAKA.out.assembly
    versions = ch_versions                     // channel: [ versions.yml ]
}

