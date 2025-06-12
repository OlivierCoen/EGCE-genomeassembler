include { PURGEDUPS_PURGEDUPS          } from '../../../modules/nf-core/purgedups/purgedups'
include { PURGEDUPS_CALCUTS            } from '../../../modules/local/purgedups/calcuts'
include { PURGEDUPS_PBCSTAT            } from '../../../modules/nf-core/purgedups/pbcstat'
include { PURGEDUPS_GETSEQS            } from '../../../modules/local/purgedups/getseqs'
include { PURGEDUPS_SPLITFA            } from '../../../modules/nf-core/purgedups/splitfa'
include { PURGEDUPS_HISTPLOT           } from '../../../modules/nf-core/purgedups/histplot'
include { MINIMAP2_SELF_ALIGNMENT      } from '../../../modules/local/minimap2/self_align'

include { MAP_TO_REFERENCE_MINIMAP2      } from '../map_to_reference/minimap2/main'
include { MAP_TO_REFERENCE_WINNOWMAP     } from '../map_to_reference/winnowmap/main'

workflow HAPLOTIG_PURGING {

    take:
    ch_reads
    ch_assemblies

    main:

    ch_versions = Channel.empty()

    def bam_format = false
    if ( params.mapper == 'winnowmap' ) {

        MAP_TO_REFERENCE_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_WINNOWMAP.out.paf_ref.set { ch_paf_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_WINNOWMAP.out.versions )

    } else {

        MAP_TO_REFERENCE_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_REFERENCE_MINIMAP2.out.paf_ref.set { ch_paf_ref }
        ch_versions = ch_versions.mix ( MAP_TO_REFERENCE_MINIMAP2.out.versions )
    }

    ch_paf_ref
        .map { meta, paf, ref -> [ meta, paf ] }
        .set { ch_paf }

    PURGEDUPS_PBCSTAT( ch_paf )
    PURGEDUPS_PBCSTAT.out.stat.set { ch_stats }

    PURGEDUPS_CALCUTS(
        ch_stats,
        params.assembly_mode
    )
    PURGEDUPS_CALCUTS.out.cutoff.set { ch_cutoffs }

    ch_stats
        .join( ch_cutoffs )
        .set { histplot_input }

    PURGEDUPS_HISTPLOT ( histplot_input )

    PURGEDUPS_SPLITFA ( ch_assemblies )
    MINIMAP2_SELF_ALIGNMENT ( PURGEDUPS_SPLITFA.out.split_fasta )

    // Purge dups
    PURGEDUPS_PBCSTAT.out.basecov
        .join( ch_cutoffs )
        .join( MINIMAP2_SELF_ALIGNMENT.out.paf )
        .set { ch_purgedups_input}

    PURGEDUPS_PURGEDUPS ( ch_purgedups_input )

    // Get seqs
    ch_assemblies
        .join( PURGEDUPS_PURGEDUPS.out.bed )
        .set { ch_getseqs_input }

    PURGEDUPS_GETSEQS ( ch_getseqs_input )

    ch_versions = ch_versions
                    .mix ( PURGEDUPS_PBCSTAT.out.versions )
                    .mix ( PURGEDUPS_SPLITFA.out.versions )
                    .mix ( PURGEDUPS_PURGEDUPS.out.versions )


    emit:
    purged_assemblies                      = PURGEDUPS_GETSEQS.out.purged
    versions                               = ch_versions                     // channel: [ versions.yml ]
}

