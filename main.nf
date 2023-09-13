#!/usr/bin/env nextflow
/*
========================================================================================
    genepi/nf-imputationserver
========================================================================================
    Github : https://github.com/genepi/imputationserver2
    Author: Lukas Forer / Sebastian Schönherr
    ---------------------------
*/

nextflow.enable.dsl = 2

if (params.refpanel_yaml){
    params.refpanel = RefPanelUtil.loadFromFile(params.refpanel_yaml)
    println params.refpanel
}

requiredParams = [
    'project', 'files', 'output', 'refpanel'
]

for (param in requiredParams) {
    if (params[param] == null) {
      exit 1, "Parameter ${param} is required."
    }
}


// create random password when not set by user
if (params.password == null) {
    params.encryption_password = PasswordCreator.createPassword()   
} else {
    params.encryption_password = params.password
}


Channel
    .fromPath(params.files)
    .set {files}

// Find legend files from full pattern and make legend file pattern relative
params.refpanel.legend_pattern = "${params.refpanel.legend}"
params.refpanel.legend = "./${file(params.refpanel.legend).fileName}"
legend_files_ch = Channel.from ( 1..22 )
        .map { it -> file(params.refpanel.legend_pattern.replaceAll('\\$chr', it.toString())) }



include { INPUT_VALIDATION } from './workflows/input_validation'
include { QUALITY_CONTROL } from './workflows/quality_control'
include { PHASING } from './workflows/phasing'
include { IMPUTATION } from './workflows/imputation'
include { ENCRYPTION } from './workflows/encryption'
include { ANCESTRY_ESTIMATION } from './workflows/ancestry_estimation'

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/


workflow {

    println "Welcome to ${params.service.name}"

    if (params.imputation.enabled){ 

        INPUT_VALIDATION()
        
        QUALITY_CONTROL(
            INPUT_VALIDATION.out,
            legend_files_ch.collect()
        )

        if ("${params.mode}" != 'qc-only') {

            PHASING(
                QUALITY_CONTROL.out.chunks_vcf,
                QUALITY_CONTROL.out.chunks_csv
            )

            if ("${params.mode}" == 'imputation') {
            
                IMPUTATION(
                    PHASING.out
                )
                
                ENCRYPTION(
                    IMPUTATION.out
                )
            }
        }
    }
    
    if (params.ancestry.enabled){
        ANCESTRY_ESTIMATION()
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