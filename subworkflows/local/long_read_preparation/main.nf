include { PORECHOP_ABI                       } from '../../../modules/nf-core/porechop/abi'
include { CHOPPER                            } from '../../../modules/local/chopper'
include { SEQKIT_SEQ                         } from '../../../modules/nf-core/seqkit/seq'
//include { SEQKIT_SANA                        } from '../../../modules/local/seqkit/sana'
include { FASTQC as FASTQC_RAW               } from '../../../modules/local/fastqc'
include { FASTQC as FASTQC_PREPARED_READS    } from '../../../modules/local/fastqc'
include { NANOQ                              } from '../../../modules/local/nanoq'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow LONG_READ_PREPARATION {

    take:
    ch_reads

    main:

    // the pipeline accepts reads in fasta / fastq format
    ch_reads = ch_reads
                .filter {
                    meta, reads ->
                        reads.name.endsWith('.fastq') || reads.name.endsWith('.fastq.gz') || reads.name.endsWith('.fq') || reads.name.endsWith('.fq.gz')
                }

    //SEQKIT_SANA(ch_reads)
    //ch_reads = SEQKIT_SANA.out.fastq

    // ---------------------------------------------------------------------
    // Quality control on raw reads
    // ---------------------------------------------------------------------

    if ( !params.skip_long_reads_fastqc_raw ) {
        FASTQC_RAW ( ch_reads )
    }

    // ---------------------------------------------------------------------
    // Trimming
    // ---------------------------------------------------------------------

    if ( !params.skip_long_reads_trimming ) {

        PORECHOP_ABI( ch_reads, [] )
        ch_reads    = PORECHOP_ABI.out.reads

    }

    // ---------------------------------------------------------------------
    // Filtering
    // ---------------------------------------------------------------------

    if ( !params.skip_long_reads_filtering ) {

        if ( params.filtering_tool == "chopper" ) {

            CHOPPER( ch_reads, [] )
            ch_reads    = CHOPPER.out.fastq

        } else { // seqkit seq

            SEQKIT_SEQ( ch_reads )
            ch_reads    = SEQKIT_SEQ.out.fastx

        }

    }

    // ---------------------------------------------------------------------
    // Quality control on trimmed / filtered reads
    // ---------------------------------------------------------------------

    if ( !params.skip_long_reads_fastqc_prepared ) {
        FASTQC_PREPARED_READS ( ch_reads )
    }

    if ( !params.skip_long_read_nanoq ) {
        NANOQ( ch_reads )
    }


    emit:
    prepared_reads      = ch_reads
}
