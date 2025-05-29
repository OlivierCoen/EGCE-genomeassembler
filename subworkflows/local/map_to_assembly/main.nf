include { MINIMAP2_ALIGN as ALIGN                    } from '../../../modules/local/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS            } from '../../local/bam_stats_samtools/main'

workflow MAP_TO_ASSEMBLY {
    take:
    ch_reads
    ch_genome_assembly

    main:

    ch_versions = Channel.empty()
    // ---------------------------------------------------
    // Alignment to respective assembly
    // ---------------------------------------------------
    ch_reads
        .combine( ch_genome_assembly, by: 0 )  // cartesian product with meta as matching key
        .set { align_input }

    def bam_format = true
    ALIGN( align_input, bam_format )

    ALIGN.out.bam.set { aln_to_assembly_bam_ref }
    ALIGN.out.index.set { aln_to_assembly_bai }

    // ---------------------------------------------------
    // BAM stats
    // ---------------------------------------------------

    aln_to_assembly_bam_ref
        .join( aln_to_assembly_bai )
        .set { aln_to_assembly_bam_ref_bai }

    BAM_STATS( aln_to_assembly_bam_ref_bai )

    ch_versions = ch_versions
                    .mix(BAM_STATS.out.versions)

    emit:
    aln_to_assembly_bam_ref
    versions = ch_versions
}
