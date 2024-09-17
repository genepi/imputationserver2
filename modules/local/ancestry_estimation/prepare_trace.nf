import groovy.json.JsonOutput

process PREPARE_TRACE {

    label 'ancestry'
    
    input:
    path(vcf_files)
    path(reference_sites)

    output:
    path("*.batch"), emit: batches
    path("study.merged.vcf.gz"), emit: vcf

    script:
    def avail_mem = 1024
    if (!task.memory) {
        log.info '[PREPARE_TRACE] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    java -Xmx${avail_mem}M -jar /opt/imputationserver-utils/imputationserver-utils.jar \
        prepare-trace \
        --batch-size ${params.ancestry.batch_size} \
        --output ./ \
        --reference-sites ${reference_sites} \
        --build ${params.build} \
        --report cloudgene.report.json \
        *.vcf.gz
    """

}
