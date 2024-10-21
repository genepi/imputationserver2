#!/usr/bin/env nextflow
/*
========================================================================================
    genepi/nf-imputationserver
========================================================================================
    Github : https://github.com/genepi/nf-imputationserver
    Author: Lukas Forer & Sebastian Schönherr
    ---------------------------
*/

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
def phasing_engine = params.phasing.engine

def run_imputation = !(params.phasing.engine == 'beagle' && params.phasing.impute)

if (phasing_engine != 'eagle' && phasing_engine != 'beagle' && phasing_engine != 'no_phasing' ) {
    println "::error:: For phasing, only options 'eagle', 'beagle' or 'no_phasing' are allowed."
    exit 1
}


// create random password when not set by user
if (params.password == null) {
    params.encryption_password = PasswordCreator.createPassword()   
} else {
    params.encryption_password = params.password
}

//set default population to "off" when allele_frequency_population is null
params.population = params.allele_frequency_population ?: "off"

Channel
    .fromPath(params.files)
    .set {files}

files.ifEmpty {
    println "::error:: No vcf.gz input files detected."
    exit 1
}

// Find site files from full pattern and make site file pattern relative
params.refpanel.sites_pattern = "${params.refpanel.sites}"
params.refpanel.sites = "./${file(params.refpanel.sites).fileName}"

site_files_ch = Channel.of(1..22, 'X', 'MT')
    .map {
        it -> 
            def sites_file = file(PatternUtil.parse(params.refpanel.sites_pattern, [chr: it]))
            def sites_file_index = file(PatternUtil.parse(params.refpanel.sites_pattern+ ".tbi", [chr: it]))
            
            if(!sites_file.exists()){
                return null;
            }  

            if(sites_file.exists() && !sites_file_index.exists()){
                error "Missing tabix index for " + sites_file
            }  
        
            return tuple(sites_file, sites_file_index); 
    }

include { INPUT_VALIDATION } from './workflows/input_validation'
include { QUALITY_CONTROL } from './workflows/quality_control'
include { PHASING } from './workflows/phasing'
include { IMPUTATION } from './workflows/imputation'
include { ENCRYPTION } from './workflows/encryption'
include { ANCESTRY_ESTIMATION } from './workflows/ancestry_estimation'
include { PGS_CALCULATION } from './workflows/pgs_calculation'

// process MERGE_ALL_PHASED_VCF {

//     label 'merge_all_phased_vcf'

//     publishDir params.output, mode: 'copy'
//     tag "Merge all phased VCF chunks"

//     input:
//     path chunk_vcf_list

//     output:
//     path "all_chromosomes.phased.vcf.gz", emit: merged_phased_vcf

//     script:
//     def num_threads = "nproc".execute().text.trim()

//     """
//     # Index any VCF files that are not indexed yet
//     for vcf in ${chunk_vcf_list.join(' ')}; do
//         if [ ! -f \${vcf}.tbi ]; then
//             tabix -p vcf \${vcf}
//         fi
//     done

//     # Merge all phased VCF chunks into one file
//     bcftools concat --threads ${num_threads} -Oz -o all_chromosomes.phased.vcf.gz ${chunk_vcf_list.join(' ')}
//     """
// }
process MERGE_ALL_PHASED_VCF {

    label 'merge_all_phased_vcf'

    publishDir "${params.output}/final_vcf", mode: 'copy'
    tag "Move all phased VCF chunks"

    input:
    path chunk_vcf_list

    output:
    path chunk_vcf_list, emit: moved_vcf_files

    script:
    """
    # Create the final_vcf folder if it does not exist
    mkdir -p ${params.output}/final_vcf

    # Move all the VCF chunks to the final_vcf folder
    for vcf in ${chunk_vcf_list.join(' ')}; do
        cp \${vcf} ${params.output}/final_vcf/
        if [ -f \${vcf}.tbi ]; then
            cp \${vcf}.tbi ${params.output}/final_vcf/
        fi
    done
    """
}

def chromosomeSortKey(chr) {
    if (chr.isInteger()) {
        return [0, chr.toInteger()] // Numeric chromosomes have higher priority
    } else {
        // Define a custom order for non-numeric chromosomes if desired
        // For example, X < Y < MT < others
        switch(chr.toUpperCase()) {
            case 'X': return [1, 1]
            case 'Y': return [1, 2]
            case 'MT': return [1, 3]
            default: return [1, 4, chr] // Others sorted lexicographically
        }
    }
}

workflow {

    println "Welcome to ${params.service.name} (${workflow.manifest.version})"

    if (params.imputation.enabled){

        INPUT_VALIDATION()

        QUALITY_CONTROL(
            INPUT_VALIDATION.out.validated_files,
            INPUT_VALIDATION.out.validation_report,
            site_files_ch.collect()
        )
       
        // check if QC chunks exist in case QC failed
        QUALITY_CONTROL.out.qc_metafiles.ifEmpty {
                error "QC step failed"
        }

        if (params.mode == 'imputation') {

            phased_ch =  QUALITY_CONTROL.out.qc_metafiles
            if (phasing_engine != 'no_phasing') { 

                PHASING(
                    QUALITY_CONTROL.out.qc_metafiles
                )

                phased_ch = PHASING.out.phased_ch
            }

            if (run_imputation) {
                IMPUTATION(
                    phased_ch
                )

                if (params.merge_results === true) {
                    ENCRYPTION(
                        IMPUTATION.out.groupTuple()
                    )
                }
            } else {
                if (params.merge_results === true) {

                    phased_ch
                    .toSortedList { a, b ->
                        def cmpChr = a[0] <=> b[0]
                        if (cmpChr != 0) return cmpChr
                        def cmpStart = a[1] <=> b[1]
                        if (cmpStart != 0) return cmpStart
                        return a[2] <=> b[2]
                    }
                    .map { list -> list.collect { it[4] } } // Collect the vcf_path
                    .flatten()
                    .collect()
                    .set { sorted_phased_chunks }

                    MERGE_ALL_PHASED_VCF(
                        sorted_phased_chunks
                    )
                }
            }
            
        }
    }
    
}

workflow.onComplete {
    //TODO: use templates
    //TODO: move in EmailHelper class
        if (!workflow.success) {
        def statusMessage = workflow.exitStatus != null  || workflow.errorReport == "QC step failed" ? "failed" : "canceled"
        if (params.send_mail && params.user.email != null){
            sendMail{
                to "${params.user.email}"
                subject "[${params.service.name}] Job ${params.project} ${statusMessage}" 
                body "Dear ${params.user.name}, \n Your job has been ${statusMessage}.\n\n More details can be found at the following link: ${params.service.url}/index.html#!jobs/${params.project}"
            }
        }
        println "::error:: Imputation job ${statusMessage}." 
        return
    }

    //submit counters for successful imputation jobs  
    if (params.mode == 'imputation') {
        println "::submit-counter name=samples::"
        println "::submit-counter name=genotypes::"
        println "::submit-counter name=chromosomes::"
        println "::submit-counter name=runs::"

        println "::set-value-and-submit name=reference_panel::${params.refpanel.id}"
        println "::set-value-and-submit name=phasing_engine::${phasing_engine}"
        println "::set-value-and-submit name=genome_build::${params.build}"
    }

    // imputation job
    if (params.merge_results === true && params.encryption.enabled === true) {

        if (params.send_mail && params.user.email != null) {
            sendMail{
                to "${params.user.email}"
                subject "[${params.service.name}] Job ${params.project} is complete"
                body "Dear ${params.user.name}, \n Your imputation job has finished succesfully. The password for the imputation results is: ${params.encryption_password}\n\n You can download the results from the following link: ${params.service.url}/index.html#!jobs/${params.project}"
            }
            println "::message:: Data have been exported successfully. We have sent a notification email to <b>${params.user.email}</b>"
        } else {
            println "::message:: Data have been exported successfully. We encrypted the results with the following password: <b>${params.encryption_password}</b>"
        }
        return
    }

    //PGS job
    if (params.send_mail && params.user.email != null) {
        sendMail{
            to "${params.user.email}"
            subject "[${params.service.name}] Job ${params.project} is complete"
            body "Dear ${params.user.name}, \n Your PGS job has finished successfully. \n\n You can download the results from the following link: ${params.service.url}/index.html#!jobs/${params.project}"
        }
        println "::message:: Data have been exported successfully. We have sent a notification email to <b>${params.user.email}</b>"
    } else {
        println "::message:: Data have been exported successfully."
    }
 
}