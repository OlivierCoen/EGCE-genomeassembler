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

    // --------------------------------------------------------
    // CORRECT
    // --------------------------------------------------------
    PECAT_CORRECT (
        ch_reads,
        PECAT_SPLIT_CONFIGS.out.correct.first()
    )

    // --------------------------------------------------------
    // FIRST ASSEMBLY
    // --------------------------------------------------------
    ch_reads
        .join ( PECAT_CORRECT.out.results )
        .set { pecat_first_assembly_input }

    PECAT_FIRST_ASSEMBLY (
        pecat_first_assembly_input,
        PECAT_SPLIT_CONFIGS.out.first_assembly.first()
    )

    // --------------------------------------------------------
    // PHASE
    // --------------------------------------------------------
    pecat_first_assembly_input
        .join ( PECAT_FIRST_ASSEMBLY.out.results )
        .set { pecat_phase_input }

    PECAT_PHASE (
        pecat_phase_input,
        PECAT_SPLIT_CONFIGS.out.phase.first()
    )

    // --------------------------------------------------------
    // SECOND ASSEMBLY
    // --------------------------------------------------------
    pecat_phase_input
        .join ( PECAT_PHASE.out.results )
        .set { pecat_second_assembly_input }

    PECAT_SECOND_ASSEMBLY (
        pecat_second_assembly_input,
        PECAT_SPLIT_CONFIGS.out.second_assembly.first()
    )

    // --------------------------------------------------------
    // POLISH
    // --------------------------------------------------------
    pecat_second_assembly_input
        .join ( PECAT_SECOND_ASSEMBLY.out.results )
        .set { pecat_polish_input }

    PECAT_POLISH (
        pecat_polish_input,
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

