import groovy.json.JsonOutput

process PREPARE_TRACE {

    publishDir params.output, mode: 'copy'

    input:
    path(vcf_files)
    path(reference_sites)

    output:
    path("*.batch"), emit: batches
    path("study.merged.vcf.gz"), emit: vcf

    script:
    """
    java -jar /opt/imputationserver-utils/imputationserver-utils.jar \
        prepare-trace \
        --batch-size ${params.ancestry.batch_size} \
        --output ./ \
        --reference-sites ${reference_sites} \
        --build ${params.build} \
        --report cloudgene.report.json \
        *.vcf.gz
    """

}
