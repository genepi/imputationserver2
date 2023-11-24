import groovy.json.JsonOutput

process ESTIMATE_ANCESTRY {

    publishDir params.output, mode: 'copy'

    input:
    path(study_pcs)
    path(reference_pc_coord)
    path(reference_samples)

    output:
    path ("estimated-population.txt"), emit:  populations

    script:
    def avail_mem = 1024
    if (!task.memory) {
        log.info '[ESTIMATE_ANCESTRY] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    # merge csv files
    csvtk concat ${study_pcs} > study.ProPC.coord

    java -Xmx${avail_mem}M -jar /opt/imputationserver-utils/imputationserver-utils.jar \
        estimate-ancestry \
        --samples ${reference_samples} \
        --reference-pc ${reference_pc_coord} \
        --study-pc study.ProPC.coord \
        --max-pcs ${params.ancestry.max_pcs} \
        --k ${params.ancestry.k} \
        --threshold ${params.ancestry.threshold} \
        --output estimated-population.txt
    """

}
