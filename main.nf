#!/usr/bin/env nextflow
/*
========================================================================================
    genepi/nf-imputationserver
========================================================================================
    Github : https://github.com/genepi/nf-imputationserver
    Author: Lukas Forer / Sebastian Schönherr
    ---------------------------
*/

nextflow.enable.dsl = 2


/*
========================================================================================
    RUN IMPUTATIONSERVER Workflow
========================================================================================
*/

include { IMPUTATIONSERVER } from './workflows/imputationserver'

workflow {
    IMPUTATIONSERVER ()
}

