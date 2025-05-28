include { PECAT_SPLIT_CONFIGS        } from '../../../modules/local/pecat/split_configs/main'
include { PECAT_CORRECT              } from '../../../modules/local/pecat/correct/main'
include { PECAT_FIRST_ASSEMBLY       } from '../../../modules/local/pecat/first_assembly/main'
include { PECAT_PHASE                } from '../../../modules/local/pecat/phase/main'
include { PECAT_SECOND_ASSEMBLY      } from '../../../modules/local/pecat/second_assembly/main'
include { PECAT_POLISH               } from '../../../modules/local/pecat/polish/main'

workflow PECAT_ASSEMBLY {

    take:
    ch_reads

    main:

    ch_pecat_config_file = Channel.fromPath ( params.pecat_config_file, checkIfExists: true )
    PECAT_SPLIT_CONFIGS ( ch_pecat_config_file )

    PECAT_CORRECT (
        ch_reads,
        PECAT_SPLIT_CONFIGS.out.correct.first()
    )

    PECAT_FIRST_ASSEMBLY (
        ch_reads.join ( PECAT_CORRECT.out.results ),
        PECAT_SPLIT_CONFIGS.out.first_assembly.first()
    )

    PECAT_PHASE (
        ch_reads.join ( PECAT_FIRST_ASSEMBLY.out.results ),
        PECAT_SPLIT_CONFIGS.out.phase.first()
    )

    PECAT_SECOND_ASSEMBLY (
        ch_reads.join ( PECAT_PHASE.out.results ),
        PECAT_SPLIT_CONFIGS.out.second_assembly.first()
    )

    PECAT_POLISH (
        ch_reads.join ( PECAT_SECOND_ASSEMBLY.out.results ),
        PECAT_SPLIT_CONFIGS.out.polish.first()
    )

    emit:
    primary_assembly     = PECAT_POLISH.out.primary_assembly
    alternate_assembly   = PECAT_POLISH.out.alternate_assembly
    haplotype_1_assembly = PECAT_POLISH.out.haplotype_1_assembly
    haplotype_2_assembly = PECAT_POLISH.out.haplotype_2_assembly
    rest_first_assembly  = PECAT_POLISH.out.rest_first_assembly
    rest_second_assembly = PECAT_POLISH.out.rest_second_assembly

}

