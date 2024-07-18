import groovy.json.JsonOutput

process INPUT_VALIDATION_VCF {

    publishDir params.output, mode: 'copy', pattern: '*.{html,log}'

    input:
    path(vcf_files)

    output:
    path("*.vcf.gz"), includeInputs: true, emit: validated_files
    
    script:
    def avail_mem = 1024
    if (!task.memory) {
        log.info '[INPUT_VALIDATION_VCF] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    set +e
    echo '${JsonOutput.toJson(params.refpanel)}' > reference-panel.json

    # TODO: add contact, mail, ...
    java -Xmx${avail_mem}M -jar /opt/imputationserver-utils/imputationserver-utils.jar \
        validate \
        --population ${params.population} \
        --phasing ${params.phasing.engine} \
        --reference reference-panel.json \
        --build ${params.build} \
        --mode ${params.mode} \
        --minSamples ${params.min_samples} \
        --maxSamples ${params.max_samples} \
        --report validation_report.txt \
        --contactName ${params.service.contact == "" ? "Admin" : params.service.contact} \
        --contactEmail ${params.service.email== "" ? "admin@localhost" : params.service.email} \
        $vcf_files 
    exit_code_a=\$?

    cat validation_report.txt
    exit \$exit_code_a
    """

}
