if (params.refpanel_yaml){
    params.refpanel = RefPanelUtil.loadFromFile(params.refpanel_yaml)
}

requiredParams = [
    'project', 'files', 'output', 'refpanel'
]

for (param in requiredParams) {
    if (params[param] == null) {
      exit 1, "Parameter ${param} is required."
    }
}

//TODO create json validation file
if (params.phasing != 'eagle' && params.phasing != 'beagle' && params.phasing != 'no_phasing' ) {
    exit 1, "For phasing, only options 'eagle', 'beagle' or 'no_phasing' are allowed."
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

legend_files_ch = Channel.of(1..22, 'X', 'MT')
    .map {
        it -> 
            def legend_file = file(PatternUtil.parse(params.refpanel.legend_pattern, [chr: it]))
            if(!legend_file.exists()){
                return null;
            }  
            return legend_file; 
    }


include { INPUT_VALIDATION } from './input_validation'
include { QUALITY_CONTROL } from './quality_control'
include { PHASING } from './phasing'
include { IMPUTATION } from './imputation'
include { ENCRYPTION } from './encryption'
include { ANCESTRY_ESTIMATION } from './ancestry_estimation'
include { PGS_CALCULATION } from './pgs_calculation'

workflow IMPUTATIONSERVER {

    println "Welcome to ${params.service.name}"

    if (params.imputation.enabled){ 

        INPUT_VALIDATION()
        
        QUALITY_CONTROL(
            INPUT_VALIDATION.out,
            legend_files_ch.collect()
        )

        if (params.mode != 'qc-only') {

            phased_ch =  QUALITY_CONTROL.out.qc_metafiles

            if (params.phasing != 'no_phasing') { 

                PHASING(
                    QUALITY_CONTROL.out.qc_metafiles
                )

                phased_ch = PHASING.out.phased_ch

            }
     
        
            if (params.mode == 'imputation') {
            
                IMPUTATION(
                    phased_ch
                )
                
                if (params.merge_results === true || params.merge_results === "true") {
                    ENCRYPTION(
                        IMPUTATION.out.groupTuple()
                    )
                }
            }
        }
    }
    
    // handles empty objects (e.g. cloudgene)
    ancestry_enabled = params.ancestry != null && params.ancestry != "" && params.ancestry.enabled

    if (ancestry_enabled) {
        ANCESTRY_ESTIMATION()
    }

    if (params.pgs.enabled) {

        PGS_CALCULATION(
            IMPUTATION.out,
            ancestry_enabled ? ANCESTRY_ESTIMATION.out : Channel.empty()
        )
        
    }
    
}


workflow.onComplete {
    //TODO: use templates
    //TODO: move in EmailHelper class
    //see https://www.nextflow.io/docs/latest/mail.html for configuration etc...
    // Nfcore Template: https://github.com/nf-core/rnaseq/blob/b89fac32650aacc86fcda9ee77e00612a1d77066/lib/NfcoreTemplate.groovy#L155

    def report = new CloudgeneReport()
   
    if (!workflow.success) {
        if (params.config.send_mail){
            sendMail{
                to "${params.user.email}"
                subject "[${params.service.name}] Job ${params.project} failed."
                body "Dear ${params.user.name}, \n Unfortunately, your job failed.\n\n More details about the errors can be found at the following link: ${params.service.url}/index.html#!jobs/${params.project}"
            }
        }
        report.ok("Imputation failed. We have sent a notification email to <b>${params.user.email}</b>") report.error("Imputation failed.")
    } else {
        // imputation results
        if ((params.merge_results === true || params.merge_results === "true") &&
            (params.encryption.enabled === true || params.encryption.enabled === "true")) {
            
            if (params.config.send_mail) {
                sendMail{
                    to "${params.user.email}"
                    subject "[${params.service.name}] Job ${params.project} is complete."
                    body "Dear ${params.user.name}, \n Your imputation job has finished succesfully. The password for the imputation results is: ${params.encryption_password}\n\n You can download the results from the following link: ${params.service.url}/index.html#!jobs/${params.project}"
                }
                report.ok("Data have been exported successfully. We have sent a notification email to <b>${params.user.email}</b>")
            } else {
                report.ok("Data have been exported successfully. We encrypted the results with the following password <b>${params.encryption_password}</b>")
            }
        //PGS results
        } else {
            if (params.config.send_mail) {
                sendMail{
                    to "${params.user.email}"
                    subject "[${params.service.name}] Job ${params.project} is complete."
                    body "Dear ${params.user.name}, \n Your PGS job has finished successfully. \n\n You can download the results from the following link: ${params.service.url}/index.html#!jobs/${params.project}"
                }
                report.ok("Data have been exported successfully. We have sent a notification email to <b>${params.user.email}</b>")
            } else {
                report.ok("Data have been exported successfully.")
            }
        }
    }
}