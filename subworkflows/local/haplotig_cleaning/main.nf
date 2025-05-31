include { PURGEDUPS_PURGEDUPS          } from '../../../modules/nf-core/purgedups/purgedups/main'
include { PURGEDUPS_CALCUTS            } from '../../../modules/nf-core/purgedups/calcuts/main'
include { PURGEDUPS_PBCSTAT            } from '../../../modules/nf-core/purgedups/pbcstat/main'
include { PURGEDUPS_GETSEQS            } from '../../../modules/nf-core/purgedups/getseqs/main'
include { PURGEDUPS_SPLITFA            } from '../../../modules/nf-core/purgedups/splitfa/main'
include { MINIMAP2_SELF_ALIGNMENT      } from '../../../modules/local/minimap2/self_align/main'

include { MAP_TO_ASSEMBLY_MINIMAP2      } from '../map_to_assembly/minimap2/main'
include { MAP_TO_ASSEMBLY_WINNOWMAP     } from '../map_to_assembly/winnowmap/main'

workflow HAPLOTIG_CLEANING {

    take:
    ch_assembly_fasta
    ch_ont_reads

    main:

    ch_versions = Channel.empty()

    def bam_format = true
    if ( params.mapper == 'winnowmap' ) {
        MAP_TO_ASSEMBLY_WINNOWMAP ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_ASSEMBLY_WINNOWMAP.out.paf_ref.set { ch_paf_ref }
        ch_versions = ch_versions.mix ( MAP_TO_ASSEMBLY_WINNOWMAP.out.versions )
    } else {
        MAP_TO_ASSEMBLY_MINIMAP2 ( ch_reads, ch_assemblies, bam_format )
        MAP_TO_ASSEMBLY_MINIMAP2.out.paf_ref.set { ch_paf_ref }
        ch_versions = ch_versions.mix ( MAP_TO_ASSEMBLY_MINIMAP2.out.versions )
    }

    ch_paf_ref
        .map { meta, paf, ref -> [ meta, paf ] }
        .set { ch_paf }

    PURGEDUPS_PBCSTAT( ch_paf )
    PURGEDUPS_CALCUTS( PURGEDUPS_PBCSTAT.out.stat )

    PURGEDUPS_SPLITFA ( ch_assembly_fasta )
    MINIMAP2_SELF_ALIGNMENT ( PURGEDUPS_SPLITFA.out.split_fasta )

    // Purge dups
    PURGEDUPS_PBCSTAT.out.basecov
        .concat( PURGEDUPS_CALCUTS.out.cutoff )
        .concat( MINIMAP2_SELF_ALIGNMENT.out.paf )
        .groupTuple()
        .map {
            meta, list ->
                [ meta, *list ]
        }
        .set { ch_purgedups_input}

    PURGEDUPS_PURGEDUPS ( ch_purgedups_input )

    // Get seqs
    ch_assembly_fasta
        .concat( PURGEDUPS_PURGEDUPS.out.bed )
        .groupTuple()
        .map {
            meta, list ->
                [ meta, *list ]
        }
        .set { ch_getseqs_input }

    PURGEDUPS_GETSEQS ( ch_getseqs_input )

    ch_versions = ch_versions
                    .mix ( PURGEDUPS_PBCSTAT.out.versions )
                    .mix ( PURGEDUPS_CALCUTS.out.versions )
                    .mix ( PURGEDUPS_SPLITFA.out.versions )
                    .mix ( PURGEDUPS_PURGEDUPS.out.versions )
                    .mix ( PURGEDUPS_GETSEQS.out.versions )


    emit:
    haplotigs = PURGEDUPS_GETSEQS.out.haplotigs
    versions = ch_versions                     // channel: [ versions.yml ]
}

