/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MULTIQC                      } from '../modules/nf-core/multiqc/main'

include { ONT_READ_PREPARATION         } from '../subworkflows/local/ont_read_preparation/main'
include { COMPUTE_KMERS                } from '../subworkflows/local/compute_kmers/main'
include { ASSEMBLY                     } from '../subworkflows/local/assembly/main'
include { HAPLOTIG_CLEANING            } from '../subworkflows/local/haplotig_cleaning/main'
include { ARIMA_MAPPING_PIPELINE_HIC   } from '../subworkflows/local/arima_mapping_pipeline_hic/main'

include { paramsSummaryMap             } from 'plugin/nf-schema'
include { paramsSummaryMultiqc         } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { customSoftwareVersionsToYAML } from '../subworkflows/local/utils_nfcore_genomeassembler_pipeline'
include { methodsDescriptionText       } from '../subworkflows/local/utils_nfcore_genomeassembler_pipeline'
include { softwareVersionsToYAML       } from '../subworkflows/nf-core/utils_nfcore_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENOMEASSEMBLER {

    take:
    ch_input // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()

    ch_input
        .map { meta, reads, hic_fastq_1, hic_fastq_2 -> [ meta, reads ] }
        .set { ch_reads }

    ch_input
        .map { meta, reads, hic_fastq_1, hic_fastq_2 -> [ meta, hic_fastq_1, hic_fastq_2 ] }
        .set { ch_hic_reads }

    if ( !params.skip_trimming || !params.skip_filtering ) {
        ONT_READ_PREPARATION ( ch_reads )
        ch_reads = ONT_READ_PREPARATION.out.prepared_reads
        ch_versions = ch_versions.mix ( ONT_READ_PREPARATION.out.versions )
    }

    ASSEMBLY ( ch_reads )
    ch_assembly = ASSEMBLY.out.primary_assembly
    ch_versions = ch_versions.mix ( ASSEMBLY.out.versions )

    ch_haplotigs = Channel.empty()
    if ( !params.skip_purging ) {
        HAPLOTIG_CLEANING(
            ch_assembly,
            ch_reads
        )
        ch_haplotigs = HAPLOTIG_CLEANING.out.haplotigs
        ch_versions = ch_versions.mix ( HAPLOTIG_CLEANING.out.versions )
    }

    // ------------------------------------------------------------------------------------
    // VERSIONS
    // ------------------------------------------------------------------------------------

    // Collate and save software versions obtained from topic channels
    // TODO: use the nf-core functions when they are adapted to channel topics

    ch_collated_versions = customSoftwareVersionsToYAML( Channel.topic('versions') )
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'software_mqc_topic_versions.yml',
            sort: true,
            newLine: true
        )
    ch_versions = ch_versions.concat( Channel.fromPath("${params.outdir}/pipeline_info/software_mqc_topic_versions.yml") )

    // Collate and save software versions
    softwareVersionsToYAML( ch_versions )
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    // ------------------------------------------------------------------------------------
    // MULTIQC
    // ------------------------------------------------------------------------------------
    ch_multiqc_files = Channel.empty()



    emit:
    multiqc_report = ch_multiqc_files



}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
