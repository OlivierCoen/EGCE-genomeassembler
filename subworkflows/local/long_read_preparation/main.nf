include { FASTPLONG                             } from '../../../modules/local/fastplong'
include { CHOPPER                               } from '../../../modules/local/chopper'
include { FASTQC as FASTQC_RAW                  } from '../../../modules/local/fastqc'
include { FASTQC as FASTQC_PREPROCESSED_READS   } from '../../../modules/local/fastqc'
include { NANOQ                                 } from '../../../modules/local/nanoq'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow LONG_READ_PREPARATION {

    take:
    ch_reads
    preprocessing_tool
    skip_long_reads_fastqc_raw
    skip_long_reads_preprocessing
    skip_long_reads_fastqc_preprocessed
    skip_long_read_nanoq

    main:

    // the pipeline accepts reads in fasta / fastq format
    ch_reads = ch_reads
                .filter {
                    meta, reads ->
                        reads.name.endsWith('.fastq') || reads.name.endsWith('.fastq.gz') || reads.name.endsWith('.fq') || reads.name.endsWith('.fq.gz')
                }

    // ---------------------------------------------------------------------
    // Quality control on raw reads
    // ---------------------------------------------------------------------

    if ( !skip_long_reads_fastqc_raw ) {
        FASTQC_RAW ( ch_reads )
    }

    // ---------------------------------------------------------------------
    // Filtering
    // ---------------------------------------------------------------------

    if ( !skip_long_reads_preprocessing ) {

        if ( preprocessing_tool == "fastplong" ) {

            FASTPLONG( ch_reads )
            ch_reads    = FASTPLONG.out.fastq

        } else if ( preprocessing_tool == "chopper" ) {

            CHOPPER( ch_reads, [] )
            ch_reads    = CHOPPER.out.fastq

        } else { error("Unrecognised preprocessing tool: $preprocessing_tool") }

    }

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    if ( !skip_long_reads_fastqc_preprocessed ) {
        FASTQC_PREPROCESSED_READS ( ch_reads )
    }

    if ( !skip_long_read_nanoq ) {
        NANOQ( ch_reads )
    }


    emit:
    prepared_reads      = ch_reads
}
