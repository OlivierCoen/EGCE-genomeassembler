include { BUSCO_BUSCO as BUSCO } from '../../../../modules/nf-core/busco/busco/main'

workflow QC_BUSCO {
    take:
    ch_assemblies

    main:

    Channel.empty().set { batch_summary }
    Channel.empty().set { short_summary_txt }
    Channel.empty().set { short_summary_json }

    def busco_config_file = []
    def clean_intermediates = false
    BUSCO(
        ch_assemblies,
        'genome',
        params.busco_lineage,
        params.busco_db ? file(params.busco_db, checkIfExists: true) : [],
        busco_config_file,
        clean_intermediates
        )

    BUSCO.out.batch_summary.set { batch_summary }
    BUSCO.out.short_summaries_txt.set { short_summary_txt }
    BUSCO.out.short_summaries_json.set { short_summary_json }
    BUSCO.out.versions.set { versions }

    emit:
    batch_summary
    short_summary_json
    short_summary_txt
    versions
}
