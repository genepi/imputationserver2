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

    println "Welcome to ${params.service.name}"

    params.password = "my-password" //PasswordCreator.createPassword()

    //TODO: Remove this debugging message.updating password is not working.
    println "Created password ${params.password}"

    if (params.imputation.enabled){ 
        IMPUTATIONSERVER2 ()
    }

    if (params.ancestry.enabled){
        ANCESTRY_ESTIMATION ()
    }

}

workflow.onComplete {
    //TODO: different text iff success or failed.
    //TODO: use templates
    //TODO: move in EmailHelper class
    //see https://www.nextflow.io/docs/latest/mail.html for configuration etc...
    if (params.config.send_mail){
        sendMail{
            to "${params.user.email}"
            subject "[${params.service.name}] Job ${params.project} is complete."
            body "Hi ${params.user.name}, how are you! The password is: ${params.password}"
        }
        println "Sent email to ${params.user.email}"
    }
}