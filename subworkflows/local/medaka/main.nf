include { MAP_TO_REFERENCE_MINIMAP2                    } from '../map_to_reference/minimap2'
include { MAP_TO_REFERENCE_WINNOWMAP                   } from '../map_to_reference/winnowmap'
include { MEDAKA_INFERENCE                             } from '../../../modules/local/medaka/inference'
include { MEDAKA_SEQUENCE                              } from '../../../modules/local/medaka/sequence'
include { EXTRACT_CONTIG_IDS                           } from '../../../modules/local/extract_contig_ids'
include { SAMTOOLS_INDEX                               } from '../../../modules/nf-core/samtools/index'


workflow MEDAKA_WORKFLOW {

    take:
    ch_reads
    ch_assemblies

    main:

    ch_versions = Channel.empty()

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    def bam_format = true
    if ( params.mapper == 'winnowmap' ) {

        MAP_TO_REFERENCE_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_WINNOWMAP.out.bam_ref.set { ch_bam_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_WINNOWMAP.out.versions )

    } else {

        MAP_TO_REFERENCE_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_MINIMAP2.out.bam_ref.set { ch_bam_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_MINIMAP2.out.versions )

    }

    ch_bam_ref
        .map { meta, bam, fasta -> [ meta, bam ] }
        .set { ch_bam }

    SAMTOOLS_INDEX ( ch_bam )

    ch_bam
        .join ( SAMTOOLS_INDEX.out.bai )
        .set { ch_bam_bai }

    // ---------------------------------------------------
    // Getting list of contigs
    // ---------------------------------------------------
    def shuffle_contigs = true
    EXTRACT_CONTIG_IDS ( ch_assemblies, shuffle_contigs )


    EXTRACT_CONTIG_IDS.out.contigs
        .map { meta, file ->
                [ meta,  file.splitCsv( strip: true ).flatten() ] // making list of contig IDS
        }
        .map { meta, contig_ids ->
                def nb_contigs = contig_ids.size()
                def chunk_size = nb_contigs.intdiv( 2 ) // getting chunk size
                [ meta, contig_ids.collate( chunk_size ) ]
        }
        .transpose() // each chunk of contig IDS becomes a separate item
        .map { meta, contig_ids ->
                [ meta, contig_ids.join(' ') ]
        }
        .set { ch_contig_groups }

    // ---------------------------------------------------
    // Polishing
    // ---------------------------------------------------

    ch_bam_bai
        .join ( ch_reads )
        .combine( ch_contig_groups, by: 0 ) // all cartesian products joined by meta
        .set { medaka_inference_input }

    MEDAKA_INFERENCE ( medaka_inference_input )

    MEDAKA_INFERENCE.out.hdf
        .groupTuple()
        .join( ch_assemblies )
        .set { medaka_sequence_input }

    MEDAKA_SEQUENCE ( medaka_sequence_input )


    emit:
    assembly = MEDAKA_SEQUENCE.out.polished_assembly
    versions = ch_versions                     // channel: [ versions.yml ]
}

