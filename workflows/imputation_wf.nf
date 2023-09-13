include { IMPUTATION } from '../modules/local/imputation'

workflow IMPUTATION_WF {

    take: 
    phased_m3vcf_ch 

    main:

    // check for '' required for testPipelineWithPhasedAndEmptyPhasing. Test case could be deleted since phasing is never '' anymore
    if ("${params.phasing}" == 'eagle' || "${params.phasing}" == '') {
    phasing_method = params.eagle_version
    }
    else if ("${params.phasing}" == 'beagle') {
    phasing_method = params.beagle_version
    }
    else if ("${params.phasing}" == 'no_phasing') {
    phasing_method = "n/a"
    }


    if (params.refpanel.mapMinimac == null) { 
        minimac_map = []
    } else {
          minimac_map = file(params.refpanel.mapMinimac, checkIfExists: true)
    }

    IMPUTATION ( 
        phased_m3vcf_ch, 
        minimac_map, 
        phasing_method
    )

    emit: 
    IMPUTATION.out.imputed_chunks.groupTuple()
}
