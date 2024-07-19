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
            it -> 
                def genotypes_file = file(PatternUtil.parse(params.refpanel.genotypes, [chr: it]))
                    if(!genotypes_file.exists()){
                        return null;
                    }
                return tuple(it.toString(),genotypes_file); 
        }

    phased_m3vcf_ch = phased_ch.combine(minimac_m3vcf_ch, by: 0)

    // load correct minimac params
    def imputation_mode = getParamsForMode(params.imputation_mode)

    MINIMAC4 ( 
        phased_m3vcf_ch, 
        minimac_map,
        params.refpanel.build,        
        imputation_mode.window,
        imputation_mode.minimac_min_ratio,
        imputation_mode.min_r2,
        imputation_mode.decay,
        imputation_mode.diff_threshold,
        imputation_mode.prob_threshold
    )

    imputed_chunks_modified = MINIMAC4.out.imputed_chunks.
        map { 
            tuple ->
                if (tuple[0].startsWith('X.')){
                    tuple[0] = 'X'
                    tuple[3] = updateChrX(tuple[3]) 
                    tuple[4] = updateChrX(tuple[4]) 
                    tuple[5] = updateChrX(tuple[5]) 
                }
                return tuple
            }

    emit: 
    imputed_chunks = imputed_chunks_modified
}

public static String updateChrX(Object value) {
    //update value
    String updadedValue=value.toString().replaceAll('PAR1','1').replaceAll('nonPAR','2').replaceAll('PAR2','3');
    //rename file
    file(value).renameTo(updadedValue) 
    return updadedValue
}


def getParamsForMode(String mode) {
    def imputation_params = [:]
    
    switch (mode) {
        case 'default':
            imputation_params = params.imputation
            break
        case 'hla':
            imputation_params = params.imputation_hla
            break
        default:
            throw new IllegalArgumentException("Unknown mode: $mode")
    }
    
    return imputation_params
}