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
    """
    # merge csv files
    csvtk concat ${study_pcs} > study.ProPC.coord

    java -jar /opt/imputationserver-utils/imputationserver-utils.jar \
        estimate-popluation \
        --samples ${reference_samples} \
        --reference-pc ${reference_pc_coord} \
        --study-pc study.ProPC.coord \
        --max-pcs ${params.ancestry.max_pcs} \
        --k ${params.ancestry.k} \
        --threshold ${params.ancestry.threshold} \
        --output estimated-population.txt

    """

}
