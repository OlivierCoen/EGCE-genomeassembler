include { PECAT_CORRECT              } from '../../../modules/local/pecat/correct/main'
include { PECAT_FIRST_ASSEMBLY       } from '../../../modules/local/pecat/first_assembly/main'
include { PECAT_PHASE                } from '../../../modules/local/pecat/phase/main'
include { PECAT_SECOND_ASSEMBLY      } from '../../../modules/local/pecat/second_assembly/main'
include { PECAT_POLISH               } from '../../../modules/local/pecat/polish/main'

workflow PECAT_ASSEMBLY {

    take:
    ch_reads

    main:

    ch_versions = Channel.empty()

    ch_pecat_config_file = Channel.fromPath ( params.pecat_config_file, checkIfExists: true )

    PECAT_CORRECT (
        ch_reads,
        ch_pecat_config_file
    )

    PECAT_FIRST_ASSEMBLY (
        ch_reads.join ( PECAT_CORRECT.out.results ),
        ch_pecat_config_file
    )

    PECAT_PHASE (
        ch_reads.join ( PECAT_FIRST_ASSEMBLY.out.results ),
        ch_pecat_config_file
    )

    PECAT_SECOND_ASSEMBLY (
        ch_reads.join ( PECAT_PHASE.out.results ),
        ch_pecat_config_file
    )

    PECAT_POLISH (
        ch_reads.join ( PECAT_SECOND_ASSEMBLY.out.results ),
        ch_pecat_config_file
    )

    emit:
    primary_assembly     = PECAT_POLISH.out.primary_assembly
    alternate_assembly   = PECAT_POLISH.out.alternate_assembly
    haplotype_1_assembly = PECAT_POLISH.out.haplotype_1_assembly
    haplotype_2_assembly = PECAT_POLISH.out.haplotype_2_assembly
    rest_first_assembly  = PECAT_POLISH.out.rest_first_assembly
    rest_second_assembly = PECAT_POLISH.out.rest_second_assembly

    versions = ch_versions                     // channel: [ versions.yml ]
}

