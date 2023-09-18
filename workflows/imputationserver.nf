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

// TODO: improve no_phasing case
phasing_reference_ch = Channel.empty()
phasing_map_ch = Channel.empty()

 if ("${params.phasing}" == 'eagle' && "${params.refpanel.refEagle}" != null) {

    phasing_map_ch = file(params.refpanel.mapEagle, checkIfExists: false)

    autosomes_eagle_ch =  Channel.from ( 1..22)
    .map { it -> tuple(it.toString(), file("$params.refpanel.refEagle".replaceAll('\\$chr', it.toString())),file("$params.refpanel.refEagle".replaceAll('\\$chr', it.toString())+'.csi')) }

    non_autosomes_eagle_ch =  Channel.from ( 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')
    .map { it -> tuple(it.toString(), file("$params.refpanel.refEagle".replaceAll('\\$chr', it.toString())),file("$params.refpanel.refEagle".replaceAll('\\$chr', it.toString())+'.csi')) }

    phasing_reference_ch = autosomes_eagle_ch.concat(non_autosomes_eagle_ch)

    }

if ("${params.phasing}" == 'beagle' && "${params.refpanel.refBeagle}" != null) {

    autosomes_beagle_ch = Channel.from ( 1..22 )
    .map { it -> tuple(it.toString(), file("$params.refpanel.refBeagle".replaceAll('\\$chr', it.toString()))) }

    non_autosomes_beagle_ch = Channel.from ( 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')
    .map { it -> tuple(it.toString(), file("$params.refpanel.refBeagle".replaceAll('\\$chr', it.toString()))) }

    phasing_reference_ch = autosomes_beagle_ch.concat(non_autosomes_beagle_ch)

    autosomes_beagle_map_ch = Channel.from ( 1..22 )
    .map { it -> tuple(it.toString(), file("$params.refpanel.mapBeagle".replaceAll('\\$chr', it.toString()))) }

    non_autosomes_beagle_map_ch = Channel.from (  'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT' )
    .map { it -> tuple(it.toString(), file("$params.refpanel.mapBeagle".replaceAll('\\$chr', it.toString()))) }

    phasing_map_ch = autosomes_beagle_map_ch.concat(non_autosomes_beagle_map_ch)
}


autosomes_m3vcf_ch = Channel.from ( 1..22 )
.map { it -> tuple(it.toString(), file("$params.refpanel.genotypes".replaceAll('\\$chr', it.toString()))) }

non_autosomes_m3vcf_ch = Channel.from ( 'X.nonPAR', 'X.PAR1', 'X.PAR2', 'MT')
.map { it -> tuple(it.toString(), file("$params.refpanel.genotypes".replaceAll('\\$chr', it.toString()))) }

minimac_m3vcf_ch = autosomes_m3vcf_ch.concat(non_autosomes_m3vcf_ch)



include { INPUT_VALIDATION } from './input_validation'
include { QUALITY_CONTROL } from './quality_control'
include { PHASING } from './phasing'
include { IMPUTATION } from './imputation'
include { ENCRYPTION } from './encryption'
include { ANCESTRY_ESTIMATION } from './ancestry_estimation'

workflow IMPUTATIONSERVER {

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
                QUALITY_CONTROL.out.chunks_csv,
                phasing_reference_ch,
                phasing_map_ch
            )

            phased_m3vcf_ch = PHASING.out.phased_ch.combine(minimac_m3vcf_ch, by: 0)

            if ("${params.mode}" == 'imputation') {
            
                IMPUTATION(
                    phased_m3vcf_ch
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
    //TODO: use templates
    //TODO: move in EmailHelper class
    //see https://www.nextflow.io/docs/latest/mail.html for configuration etc...
   
    def report = new CloudgeneReport()
   
    //job failed
    if (!workflow.success) {
        if (params.config.send_mail){
            sendMail{
                to "${params.user.email}"
                subject "[${params.service.name}] Job ${params.project} failed."
                body "Hi ${params.user.name}, the job failed :("
            }
        }
        report.error("Imputation failed.")
        return
    }

    //job successful
    if (params.config.send_mail){
        sendMail{
            to "${params.user.email}"
            subject "[${params.service.name}] Job ${params.project} is complete."
            body "Hi ${params.user.name}, how are you! The password is: ${params.encryption_password}"
        }
        report.ok("Sent email with password to <b>${params.user.email}</b>")
    } else {
        report.ok("Encrypted results with password <b>${params.encryption_password}</b>")
    }
}