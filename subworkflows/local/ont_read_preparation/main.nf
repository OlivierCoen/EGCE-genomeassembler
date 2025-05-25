include { PORECHOP_ABI                 } from '../../../modules/nf-core/porechop/abi/main'
include { CHOPPER                   } from '../../../modules/nf-core/chopper/main'

workflow ONT_READ_PREPARATION {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()

    if ( !params.skip_trimming ) {
        ch_customer_reads = Channel.value( [] )
        PORECHOP_ABI( ch_reads, ch_customer_reads )
        PORECHOP_ABI.out.reads.set { ch_reads }
    }

    if ( !params.skip_filtering ) {
        ch_contaminant_fasta = Channel.value( [] )
        CHOPPER( ch_reads, ch_contaminant_fasta )
        CHOPPER.out.fastq.set { ch_reads }
    }

    emit:
    prepared_reads = ch_reads

    versions = ch_versions                     // channel: [ versions.yml ]
}

