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


// create random password when not set by user
if (params.password == null) {
    params.encryption_password = PasswordCreator.createPassword()   
} else {
    params.encryption_password = params.password
}

workflow {

    println "Welcome to ${params.service.name}"

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
   
    //TODO: remove debug message
    println "Used password ${params.encryption_password}"
   
    if (params.config.send_mail){

        def subjectTitle = "[${params.service.name}] Job ${params.project} is complete."
        if (!workflow.success) {
            subjectTitle = "[${params.service.name}] Job ${params.project} failed."
        }

        sendMail{
            to "${params.user.email}"
            subject subjectTitle
            body "Hi ${params.user.name}, how are you! The password is: ${params.encryption_password}"
        }
        println "Sent email to ${params.user.email}"
    }
}