include { PORECHOP_ABI                 } from '../../../modules/nf-core/porechop/abi/main'
include { CHOPPER                   } from '../../../modules/nf-core/chopper/main'

workflow ONT_READ_PREPARATION {

    take:
    ch_input

    main:

    ch_versions = Channel.empty()

    if ( !params.skip_trimming ) {
        ch_customer_reads = Channel.of( [] )
        PORECHOP_ABI( ch_input, ch_customer_reads )
        PORECHOP_ABI.out.reads.set { ch_reads }
    }

    if ( !params.skip_filtering ) {
        CHOPPER( ch_reads )
        CHOPPER.out.fastq.set { ch_reads }
    }

    emit:
    prepared_reads = ch_reads

    versions = ch_versions                     // channel: [ versions.yml ]
}

