include { MINIMAC4 } from '../modules/local/imputation/minimac4'

workflow IMPUTATION {

    take: 
    phased_m3vcf_ch 

    main:

    // check for '' required for testPipelineWithPhasedAndEmptyPhasing. Test case could be deleted since phasing is never '' anymore
    if ("${params.phasing}" == 'eagle' || "${params.phasing}" == '') {
        phasing_method = params.eagle_version
    } else if ("${params.phasing}" == 'beagle') {
        phasing_method = params.beagle_version
    } else if ("${params.phasing}" == 'no_phasing') {
        phasing_method = "n/a"
    }


    if (params.refpanel.mapMinimac == null) { 
        minimac_map = []
    } else {
        minimac_map = file(params.refpanel.mapMinimac, checkIfExists: true)
    }

    MINIMAC4 ( 
        phased_m3vcf_ch, 
        minimac_map, 
        phasing_method
    )

    emit: 
    imputed_chunks = MINIMAC4.out.imputed_chunks.groupTuple()
}
