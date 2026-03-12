include { FLYE                                 } from '../../../modules/local/flye'
include { HIFIASM_WORKFLOW                     } from '../hifiasm'
include { ASSEMBLY_STATS                       } from '../../../modules/local/assembly_stats'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


workflow DRAFT_ASSEMBLY {

    take:
    ch_reads

    main:

    ch_alternate_assemblies = channel.empty()

     if ( params.assembler == "flye" ) {

        FLYE(
            ch_reads.join( channel.topic('mean_qualities') )
        )

        ch_assemblies = FLYE.out.fasta

    } else if ( params.assembler == "hifiasm" ) {

        HIFIASM_WORKFLOW ( ch_reads )

        ch_assemblies           = HIFIASM_WORKFLOW.out.assemblies
        ch_alternate_assemblies = HIFIASM_WORKFLOW.out.draft_assembly_versions

    } else {
        error ("Unknown assembler in this subworkflow: ${params.assembler}") // this should not happen
    }

    ASSEMBLY_STATS ( ch_assemblies )

    emit:
    assemblies                       = ch_assemblies
    alternate_assemblies             = ch_alternate_assemblies

}
