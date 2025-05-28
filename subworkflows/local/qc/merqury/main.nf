include { MERQURY_MERQURY as MERQURY } from '../../../../modules/nf-core/merqury/merqury/main'
include { MERYL_COUNT                } from '../../../../modules/nf-core/meryl/count/main'

workflow QC_MERQURY {
    take:
    ch_assemblies
    ch_reads

    main:

    ch_versions = Channel.empty()

    MERYL_COUNT(
        ch_reads,
        params.meryl_k_value
    )

    MERYL_COUNT.out.meryl_db
        .join( ch_assemblies )
        .set { merqury_in }

    MERQURY( merqury_in )

    ch_versions = ch_versions
                    .mix( MERYL_COUNT.out.versions )
                    .mix( MERQURY.out.versions )

    emit:
    stats = MERQURY.out.stats
    spectra_asm_hist = MERQURY.out.spectra_asm_hist
    spectra_cn_hist = MERQURY.out.spectra_cn_hist
    assembly_qv = MERQURY.out.assembly_qv
    versions = ch_versions
}
