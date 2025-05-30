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
include { SCAFFOLDING_WITH_HIC         } from '../subworkflows/local/scaffolding_with_hic/main'

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

    // ------------------------------------------------------------------------------------
    // READ PREPARATION
    // ------------------------------------------------------------------------------------

    ONT_READ_PREPARATION ( ch_reads )
    ch_reads = ONT_READ_PREPARATION.out.prepared_reads
    ch_versions = ch_versions.mix ( ONT_READ_PREPARATION.out.versions )

    // ------------------------------------------------------------------------------------
    // ASSEMBLY
    // ------------------------------------------------------------------------------------

    ASSEMBLY ( ch_reads )
    ASSEMBLY.out.assemblies.set { ch_assembly }
    ch_versions = ch_versions.mix ( ASSEMBLY.out.versions )

    // ------------------------------------------------------------------------------------
    // HAPLOTIG CLEANING
    // ------------------------------------------------------------------------------------

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
    // SCAFFOLDING WITH HIC
    // ------------------------------------------------------------------------------------

    /*
    if ( !params.skip_scaffolding_with_hic ) {
        SCAFFOLDING_WITH_HIC ( ch_hic_reads, ch_assembly )
        ch_assembly = SCAFFOLDING_WITH_HIC.out.scaffolds_fasta
        ch_versions = ch_versions.mix ( SCAFFOLDING_WITH_HIC.out.versions )
    }
    */

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

    ch_multiqc_config = Channel.fromPath( "$projectDir/assets/multiqc_config.yml", checkIfExists: true )

    summary_params = paramsSummaryMap( workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value( paramsSummaryMultiqc(summary_params) )

    ch_multiqc_custom_config = params.multiqc_config ?
                                    Channel.fromPath(params.multiqc_config, checkIfExists: true) :
                                    Channel.empty()

    ch_multiqc_logo = params.multiqc_logo ?
                        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
                        Channel.empty()

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
                                                file(params.multiqc_methods_description, checkIfExists: true) :
                                                file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

    ch_methods_description = Channel.value( methodsDescriptionText(ch_multiqc_custom_methods_description) )

    // Adding metadata to MultiQC
    ch_multiqc_files = Channel.empty()
                            .mix( ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml') )
                            .mix( ch_collated_versions )
                            .mix( ch_methods_description.collectFile( name: 'methods_description_mqc.yaml', sort: true ) )
    // Adding data to MultiQC
    ch_multiqc_files = ch_multiqc_files
                        .mix( ONT_READ_PREPARATION.out.fastqc_raw_zip.map { meta, zip -> [ zip ] } )
                        .mix( ONT_READ_PREPARATION.out.fastqc_prepared_reads_zip.map { meta, zip -> [ zip ] } )
                        .mix( ONT_READ_PREPARATION.out.porechop_logs.map { meta, logs -> [ logs ] } )
                        .mix( ONT_READ_PREPARATION.out.nanoq_stats.map { meta, stats -> [ stats ] } )
                        .mix( ASSEMBLY.out.assembly_quast_reports )
                        .mix( ASSEMBLY.out.assembly_busco_reports.map { meta, report -> [ report ] } )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
        multiqc_report = MULTIQC.out.report.toList()

    emit:
    assembly = ch_assembly
    multiqc_report = ch_multiqc_files



}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
