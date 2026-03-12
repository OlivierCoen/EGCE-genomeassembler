include { PURGEDUPS_PURGEDUPS          } from '../../../modules/nf-core/purgedups/purgedups'
include { PURGEDUPS_CALCUTS            } from '../../../modules/local/purgedups/calcuts'
include { PURGEDUPS_PBCSTAT            } from '../../../modules/local/purgedups/pbcstat'
include { PURGEDUPS_GETSEQS            } from '../../../modules/local/purgedups/getseqs'
include { PURGEDUPS_SPLITFA            } from '../../../modules/nf-core/purgedups/splitfa'
include { PURGEDUPS_HISTPLOT           } from '../../../modules/nf-core/purgedups/histplot'
include { MINIMAP2_SELF_ALIGNMENT      } from '../../../modules/local/minimap2/self_align'
include { ASSEMBLY_STATS               } from '../../../modules/local/assembly_stats'

include { MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2      } from '../map_long_reads_to_assembly/minimap2'
include { MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP     } from '../map_long_reads_to_assembly/winnowmap'


workflow PURGE_DUPLICATES {

    take:
    ch_reads
    ch_assemblies

    main:

    def bam_format = false
    if ( params.mapper == 'winnowmap' ) {

        MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
        ch_paf_ref  = MAP_LONG_READS_TO_ASSEMBLY_WINNOWMAP.out.paf_ref

    } else {

        MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        ch_paf_ref  = MAP_LONG_READS_TO_ASSEMBLY_MINIMAP2.out.paf_ref

    }

    PURGEDUPS_PBCSTAT(
        ch_paf_ref.map { meta, paf, ref -> [ meta, paf ] }
    )
    // For assemblies where peaks were detected, there is a cutoff file
    // for others (for cwhich the rest ot the purge_dups pipelines is not triggered), there is only a flag file
    ch_stats    = PURGEDUPS_PBCSTAT.out.stat
    ch_no_peaks = PURGEDUPS_PBCSTAT.out.no_peaks

    PURGEDUPS_CALCUTS(
        ch_stats,
        params.assembly_mode
    )
    ch_cutoffs = PURGEDUPS_CALCUTS.out.cutoff

    PURGEDUPS_HISTPLOT (
        ch_stats.join( ch_cutoffs )
    )

    PURGEDUPS_SPLITFA ( ch_assemblies )
    MINIMAP2_SELF_ALIGNMENT ( PURGEDUPS_SPLITFA.out.split_fasta )

    // Purge dups
    ch_purgedups_input = PURGEDUPS_PBCSTAT.out.basecov
                            .join( ch_cutoffs )
                            .join( MINIMAP2_SELF_ALIGNMENT.out.paf )

    PURGEDUPS_PURGEDUPS ( ch_purgedups_input )

    // Get seqs
    PURGEDUPS_GETSEQS (
        ch_assemblies.join( PURGEDUPS_PURGEDUPS.out.bed )
    )
    ch_purged_assemblies = PURGEDUPS_GETSEQS.out.purged

    // In some cases, PURGEDUPS_PBCSTAT does not detect peaks, and the final steps if not triggered
    // We take the input assemblies in those cases
    ch_no_peak_assemblies = ch_assemblies
                                .join( ch_no_peaks )
                                .map{ meta, assembly, flag_file -> [ meta, assembly ] }

    ch_processed_assemblies = ch_purged_assemblies.mix( ch_no_peak_assemblies )

    // Stats
    ASSEMBLY_STATS ( ch_processed_assemblies )


    emit:
    purged_assemblies                      = ch_processed_assemblies
}
