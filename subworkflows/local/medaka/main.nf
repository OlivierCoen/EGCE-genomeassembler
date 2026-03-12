include { MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2          } from '../map_long_reads_to_assembly/minimap2'
include { MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP         } from '../map_long_reads_to_assembly/winnowmap'
include { MEDAKA_INFERENCE                             } from '../../../modules/local/medaka/inference'
include { MEDAKA_SEQUENCE                              } from '../../../modules/local/medaka/sequence'
include { EXTRACT_CONTIG_IDS                           } from '../../../modules/local/extract_contig_ids'
include { SAMTOOLS_INDEX                               } from '../../../modules/nf-core/samtools/index'


workflow MEDAKA_WORKFLOW {

    take:
    ch_reads
    ch_assemblies

    main:

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    def bam_format = true
    if ( params.mapper == 'winnowmap' ) {

        MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
        ch_bam_ref  = MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP.out.bam_ref

    } else {

        MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        ch_bam_ref  = MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2.out.bam_ref

    }

    ch_bam = ch_bam_ref.map { meta, bam, fasta -> [ meta, bam ] }

    SAMTOOLS_INDEX( ch_bam )

    ch_bam_bai = ch_bam.join( SAMTOOLS_INDEX.out.bai )

    // ---------------------------------------------------
    // Getting list of contigs
    // ---------------------------------------------------
    def shuffle_contigs = true
    EXTRACT_CONTIG_IDS ( ch_assemblies, shuffle_contigs )


    ch_contig_groups = EXTRACT_CONTIG_IDS.out.contigs
                        .map { meta, file ->
                                [ meta,  file.splitCsv( strip: true ).flatten() ] // making list of contig IDS
                        }
                        .map { meta, contig_ids ->
                                def nb_contigs = contig_ids.size()
                                [ meta, contig_ids.collate( params.medaka_contig_chunksize ) ]
                        }
                        .transpose() // each chunk of contig IDS becomes a separate item
                        .map { meta, contig_ids ->
                                [ meta, contig_ids.join(' ') ]
                        }

    // ---------------------------------------------------
    // Polishing
    // ---------------------------------------------------

    medaka_inference_input = ch_bam_bai
                                .join ( ch_reads )
                                .combine( ch_contig_groups, by: 0 ) // all cartesian products joined by meta

    MEDAKA_INFERENCE ( medaka_inference_input )

    medaka_sequence_input = MEDAKA_INFERENCE.out.hdf
                            .groupTuple()
                            .join( ch_assemblies )

    MEDAKA_SEQUENCE ( medaka_sequence_input )


    emit:
    assembly = MEDAKA_SEQUENCE.out.polished_assembly
}
