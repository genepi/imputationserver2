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

    MINIMAC4 ( 
        phased_m3vcf_ch, 
        minimac_map,
        params.refpanel.build,        
        params.imputation.window,
        params.imputation.minimac_min_ratio,
        params.imputation.min_r2,
        params.imputation.decay,
        params.imputation.diff_threshold,
        params.imputation.prob_threshold,
        params.imputation.prob_threshold_s1,
        params.imputation.min_recom
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