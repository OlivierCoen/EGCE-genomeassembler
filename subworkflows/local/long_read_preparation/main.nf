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


workflow LONG_READ_PREPARATION {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()

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
        .set { ch_branched_fastq_reads }

    PORECHOP_ABI( ch_branched_fastq_reads.trim_me, [] )

    ch_branched_fastq_reads.leave_me_alone
        .mix ( PORECHOP_ABI.out.reads )
        .set { ch_trimmed_fastq_reads }

    ch_versions = ch_versions.mix ( PORECHOP_ABI.out.versions )

    // ---------------------------------------------------------------------
    // Filtering
    // ---------------------------------------------------------------------

    ch_trimmed_fastq_reads
        .branch { meta, reads ->
            filter_me: meta.filter_reads
            leave_me_alone: !meta.filter_reads
        }
        .set { ch_branched_trimmed_fastq_reads }

    if ( params.filtering_tool == "chopper" ) {

        CHOPPER( ch_branched_trimmed_fastq_reads.filter_me, [] )

        CHOPPER.out.fastq.set { ch_filtered_fastq_reads }
        ch_versions = ch_versions.mix ( CHOPPER.out.versions )

    } else { // seqkit seq

        SEQKIT_SEQ( ch_branched_trimmed_fastq_reads.filter_me )

        SEQKIT_SEQ.out.fastx.set { ch_filtered_fastq_reads }
        ch_versions = ch_versions.mix ( SEQKIT_SEQ.out.versions )

    }

    ch_branched_trimmed_fastq_reads.leave_me_alone
        .mix ( ch_filtered_fastq_reads )
        .set { ch_prepared_fastq_reads }

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    FASTQC_PREPARED_READS ( ch_prepared_fastq_reads.filter { meta, assembly -> meta.run_fastqc_prepared } )

    NANOQ( ch_prepared_fastq_reads )


    emit:
    prepared_reads = ch_prepared_fastq_reads
    versions = ch_versions                     // channel: [ versions.yml ]
}

