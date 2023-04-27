#!/usr/bin/env nextflow
/*
========================================================================================
    genepi/gwas-regenie
========================================================================================
    Github : https://github.com/genepi/imputationserver2
    Author: Forer / Schönherr
    ---------------------------
*/

nextflow.enable.dsl = 2

include { IMPUTATIONSERVER2 } from './workflows/imputationserver2'
include { ANCESTRY_ESTIMATION } from './workflows/ancestry_estimation'

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

workflow {

    if (params.imputation.enabled){ 
        IMPUTATIONSERVER2 ()
    }

    if (params.ancestry.enabled){
        ANCESTRY_ESTIMATION ()
    }

}
