include { PORECHOP_ABI                       } from '../../../modules/nf-core/porechop/abi'
include { CHOPPER                            } from '../../../modules/nf-core/chopper'
include { SEQKIT_SEQ                         } from '../../../modules/nf-core/seqkit/seq'
include { FASTQC as FASTQC_RAW               } from '../../../modules/local/fastqc'
include { FASTQC as FASTQC_PREPARED_READS    } from '../../../modules/local/fastqc'
include { NANOQ                              } from '../../../modules/local/nanoq'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow ONT_READ_PREPARATION {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()
    ch_fastqc_raw_zip = Channel.empty()
    ch_fastqc_prepared_reads_zip = Channel.empty()
    ch_porechop_logs = Channel.empty()
    ch_nanoq_stats = Channel.empty()

    // the pipeline accepts reads in fasta format
    ch_reads
        .filter {
            meta, reads ->
                reads.name.endsWith('.fastq') || reads.name.endsWith('.fastq.gz') || reads.name.endsWith('.fq') || reads.name.endsWith('.fq.gz')
        }
        .set { ch_fastq_reads }

    // ---------------------------------------------------------------------
    // Quality control on raw reads
    // ---------------------------------------------------------------------

    FASTQC_RAW ( ch_fastq_reads.filter { meta, assembly -> meta.run_fastqc_raw } )

    // ---------------------------------------------------------------------
    // Trimming
    // ---------------------------------------------------------------------

    ch_fastq_reads
        .branch { meta, reads ->
            trim_me: meta.trim_reads
            leave_me_alone: !meta.trim_reads
        }
        .set { ch_fastq_reads }

    PORECHOP_ABI( ch_fastq_reads.trim_me, [] )

    ch_fastq_reads.leave_me_alone
        .mix ( PORECHOP_ABI.out.reads )
        .set { ch_fastq_reads }

    ch_versions = ch_versions.mix ( PORECHOP_ABI.out.versions )

    // ---------------------------------------------------------------------
    // Filtering
    // ---------------------------------------------------------------------

    ch_fastq_reads
        .branch { meta, reads ->
            filter_me: meta.filter_reads
            leave_me_alone: !meta.trim_reads
        }
        .set { ch_fastq_reads }

    if ( params.filtering_tool == "chopper" ) {

        CHOPPER( ch_fastq_reads.filter_me, [] )

        ch_fastq_reads.leave_me_alone
            .mix ( CHOPPER.out.fastq )
            .set { ch_fastq_reads }

        ch_versions = ch_versions.mix ( CHOPPER.out.versions )


    } else { // seqkit seq
        SEQKIT_SEQ( ch_fastq_reads.filter_me )

        ch_fastq_reads.leave_me_alone
            .mix ( SEQKIT_SEQ.out.fastx )
            .set { ch_fastq_reads }

        ch_versions = ch_versions.mix ( SEQKIT_SEQ.out.versions )

    }

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    FASTQC_PREPARED_READS ( ch_fastq_reads.filter { meta, assembly -> meta.run_fastqc_prepared } )

    NANOQ( ch_fastq_reads )


    emit:
    prepared_reads = ch_fastq_reads
    fastqc_raw_zip = FASTQC_RAW.out.zip
    fastqc_prepared_reads_zip = FASTQC_PREPARED_READS.out.zip
    porechop_logs = PORECHOP_ABI.out.log
    nanoq_stats = NANOQ.out.report
    versions = ch_versions                     // channel: [ versions.yml ]
}

