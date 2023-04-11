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

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

workflow {
    IMPUTATIONSERVER2 ()
}
