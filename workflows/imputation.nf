include { MINIMAC4 } from '../modules/local/imputation/minimac4'

workflow IMPUTATION {

    take: 
    phased_ch 

    main:
    if (params.refpanel.mapMinimac == null) { 
        minimac_map = []
    } else {
        minimac_map = file(params.refpanel.mapMinimac, checkIfExists: true)
    }

    chromosomes = Channel.of(1..22, 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')
    minimac_m3vcf_ch = chromosomes
        .map {
            it -> tuple(
                it.toString(),
                file(Patterns.parse(params.refpanel.genotypes, [chr: it]))
            )
        }
    phased_m3vcf_ch = phased_ch.combine(minimac_m3vcf_ch, by: 0)

    MINIMAC4 ( 
        phased_m3vcf_ch, 
        minimac_map
    )

    emit: 
    imputed_chunks = MINIMAC4.out.imputed_chunks.groupTuple()
}
