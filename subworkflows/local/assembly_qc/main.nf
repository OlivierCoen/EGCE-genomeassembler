include { MAP_TO_REFERENCE_MINIMAP2      } from '../map_to_reference/minimap2/main'
include { MAP_TO_REFERENCE_WINNOWMAP     } from '../map_to_reference/winnowmap/main'
include { QC_QUAST                      } from '../qc/quast/main'
include { QC_BUSCO                      } from '../qc/busco/main'
include { QC_MERQURY                    } from '../qc/merqury/main'


workflow ASSEMBLY_QC {

    take:
    ch_reads
    ch_assemblies

    main:
    ch_versions = Channel.empty()

    assembly_quast_reports = Channel.empty()
    assembly_busco_reports = Channel.empty()
    assembly_merqury_reports = Channel.empty()

    if ( !params.skip_quast ) {

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

        QC_QUAST( ch_bam_ref )
        QC_QUAST.out.quast_tsv.set { assembly_quast_reports }

    }

    /*
    QC on initial assembly
    */
    if ( !params.skip_busco ) {
        QC_BUSCO( ch_assemblies )
        QC_BUSCO.out.batch_summary.set { assembly_busco_reports }
        ch_versions = ch_versions.mix ( QC_BUSCO.out.versions )
    }

    if ( !params.skip_merqury ) {
        QC_MERQURY(
            ch_reads,
            ch_assemblies
        )
        QC_MERQURY.out.stats
            .join( QC_MERQURY.out.spectra_asm_hist )
            .join( QC_MERQURY.out.spectra_cn_hist )
            .join( QC_MERQURY.out.assembly_qv )
            .set { assembly_merqury_reports }
        ch_versions = ch_versions.mix ( QC_MERQURY.out.versions )
    }

    emit:
    assembly_quast_reports
    assembly_busco_reports
    assembly_merqury_reports
    versions = ch_versions                     // channel: [ versions.yml ]

}
