include { MINIMAP2_ALIGN                    } from '../../../../modules/local/minimap2/align'
// include { BAM_STATS_SAMTOOLS as BAM_STATS            } from '../../local/bam_stats_samtools/main'

workflow MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2 {

    take:
    ch_reads
    ch_genome_assembly
    bam_format

    main:

    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------

    MINIMAP2_ALIGN(
        ch_reads.combine( ch_genome_assembly, by: [0] ),  // cartesian product with meta as matching key,
        bam_format
    )

    // ---------------------------------------------------
    // BAM stats
    // ---------------------------------------------------
    /*
    if ( get_mapping_stats ) {

        aln_to_assembly_bam_ref
            .join( aln_to_assembly_bai )
            .set { aln_to_assembly_bam_ref_bai }

        BAM_STATS( aln_to_assembly_bam_ref_bai )

    }
    */

    emit:
    paf_ref = MINIMAP2_ALIGN.out.paf_ref
    bam_ref = MINIMAP2_ALIGN.out.bam_ref
    bai = MINIMAP2_ALIGN.out.index
}
