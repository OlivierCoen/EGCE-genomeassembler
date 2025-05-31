include { PORECHOP_ABI                       } from '../../../modules/nf-core/porechop/abi/main'
include { CHOPPER                            } from '../../../modules/nf-core/chopper/main'
include { SEQKIT_SEQ                         } from '../../../modules/nf-core/seqkit/seq/main'
include { FASTQC as FASTQC_RAW               } from '../../../modules/local/fastqc/main'
include { FASTQC as FASTQC_PREPARED_READS    } from '../../../modules/local/fastqc/main'
include { NANOQ                              } from '../../../modules/local/nanoq/main'


workflow ONT_READ_PREPARATION {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()
    ch_fastqc_raw_zip = Channel.empty()
    ch_fastqc_prepared_reads_zip = Channel.empty()
    ch_porechop_logs = Channel.empty()
    ch_nanoq_stats = Channel.empty()

    ch_reads
        .filter {
            meta, reads ->
                reads.name.endsWith('.fastq') || reads.name.endsWith('.fastq.gz') || reads.name.endsWith('.fq') || reads.name.endsWith('.fq.gz')
        }
        .set { ch_fastq_reads }

    // ---------------------------------------------------------------------
    // Quality control on raw reads
    // ---------------------------------------------------------------------

    if ( !params.skip_fastqc ) {
        FASTQC_RAW ( ch_fastq_reads )
        ch_fastqc_raw_zip  = FASTQC_RAW.out.zip
    }

    if ( !params.skip_nanoq ) {
        NANOQ( ch_fastq_reads )
        NANOQ.out.stats.set { ch_nanoq_stats }
    }

    // ---------------------------------------------------------------------
    // Trimming / filtering
    // ---------------------------------------------------------------------

    if ( !params.skip_trimming ) {
        PORECHOP_ABI( ch_reads, [] )
        PORECHOP_ABI.out.reads.set { ch_reads }
        ch_porechop_logs = PORECHOP_ABI.out.log
        ch_versions = ch_versions.mix ( PORECHOP_ABI.out.versions )
    }

    if ( !params.skip_filtering ) {

        if ( params.filtering_tool == "chopper" ) {
            CHOPPER( ch_reads, [] )
            CHOPPER.out.fastq.set { ch_reads }
            ch_versions = ch_versions.mix ( CHOPPER.out.versions )
        } else { // seqkit seq
            SEQKIT_SEQ( ch_reads )
            SEQKIT_SEQ.out.fastx.set { ch_reads }
            ch_versions = ch_versions.mix ( SEQKIT_SEQ.out.versions )
        }
    }

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    if ( !params.skip_fastqc && ( !params.skip_trimming || !params.skip_filtering ) ) {
        FASTQC_PREPARED_READS ( ch_reads )
        ch_fastqc_prepared_reads_zip  = FASTQC_PREPARED_READS.out.zip
    }


    emit:
    prepared_reads = ch_reads
    fastqc_raw_zip = ch_fastqc_raw_zip
    fastqc_prepared_reads_zip = ch_fastqc_prepared_reads_zip
    porechop_logs = ch_porechop_logs
    nanoq_stats = ch_nanoq_stats
    versions = ch_versions                     // channel: [ versions.yml ]
}

