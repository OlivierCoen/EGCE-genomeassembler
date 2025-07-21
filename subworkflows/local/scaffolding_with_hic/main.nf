include { ARIMA_MAPPING_PIPELINE_HIC    } from '../arima_mapping_pipeline_hic'
include { HIC_CONTACT_MAP               } from '../hic_contact_map'

include { SAMTOOLS_FAIDX                } from '../../../modules/local/samtools/faidx'
include { YAHS                          } from '../../../modules/local/yahs'
include { ASSEMBLY_STATS                } from '../../../modules/local/assembly_stats'


workflow SCAFFOLDING_WITH_HIC {

    take:
    ch_hic_reads
    ch_assemblies

    main:

    ch_versions = Channel.empty()

    // ------------------------------------------------------------------------------------
    // MAPPING OF HI-C READS TO ASSEMBLY
    // ------------------------------------------------------------------------------------

    if ( params.skip_arima_hic_mapping_pipeline ) {

        if ( params.hic_reads_mapping ) {
            ch_hic_bam = Channel.fromPath( params.hic_reads_mapping, checkExists: true )
        } else {
            error("You must provide a BAM file consisting of Hi-C reads mapped to the current assembly if you set --skip_arima_hic_mapping_pipeline")
        }

    } else {

        ARIMA_MAPPING_PIPELINE_HIC (
            ch_hic_reads,
            ch_assemblies
        )

        ARIMA_MAPPING_PIPELINE_HIC.out.alignment.set { ch_hic_bam }
        ch_versions = ch_versions.mix ( ARIMA_MAPPING_PIPELINE_HIC.out.versions )

    }

    // ------------------------------------------------------------------------------------
    // MAKING CONTACT MAP BEFORE SCAFFOLDING
    // ------------------------------------------------------------------------------------

    if ( !params.skip_hic_contact_maps ) {
        HIC_CONTACT_MAP (
            ch_hic_bam,
            ch_assemblies
        )
    }

    // ------------------------------------------------------------------------------------
    // SCAFFOLDING
    // ------------------------------------------------------------------------------------

    SAMTOOLS_FAIDX ( ch_assemblies )

    ch_hic_bam
        .join( ch_assemblies )
        .join( SAMTOOLS_FAIDX.out.fai )
        .set { yahs_input }

    YAHS ( yahs_input )
    YAHS.out.scaffolds_fasta.set { ch_scaffolded_assemblies }

    // ------------------------------------------------------------------------------------
    // COMPUTING Nx / Lx FOR NEW SCAFFOLDED ASSEMBLY
    // ------------------------------------------------------------------------------------

    ASSEMBLY_STATS ( ch_scaffolded_assemblies )


    emit:
    scaffolded_assemblies          = ch_scaffolded_assemblies
    versions                          = ch_versions                     // channel: [ versions.yml ]
}

