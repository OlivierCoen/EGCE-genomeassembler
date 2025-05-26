include { MERYL_COUNT                  } from '../../../modules/nf-core/meryl/count/main'
include { MERYL_PRINT                  } from '../../../modules/local/meryl/print/main'

workflow COMPUTE_KMERS {

    take:
    ch_assembly_fasta

    main:

    MERYL_COUNT(
        ch_assembly_fasta,
        params.meryl_k_value
    )

    MERYL_PRINT( MERYL_COUNT.out.meryl_db )


    emit:
    meryl_db = MERYL_COUNT.out.meryl_db
    repetitive_kmers = MERYL_PRINT.out.repetitive_kmers
    versions = MERYL_COUNT.out.versions

}
