import groovy.json.JsonOutput

process PREPARE_TRACE {

  publishDir params.output, mode: 'copy'

  input:
    path(vcf_files)
    path(reference_sites)

  output:
    path("*.batch"), emit: batches
    path("study.merged.vcf.gz"), emit: vcf
    path("*.html")

  script:

    config = [
        params: [
            files: './',
            batch_size: "${params.ancestry.batch_size}",
            output: './',
            reference_sites: "${reference_sites}",
            build: params.build
        ]
    ]

    """
    echo '${JsonOutput.toJson(config)}' > config.json

    java -cp /opt/imputationserver-utils/imputationserver-utils.jar \
      cloudgene.sdk.weblog.WebLogRunner \
      genepi.imputationserver.steps.TraceStep \
      config.json \
      cloudgene.log

    ccat cloudgene.log --html > 07-prepare-trace.html

    """

}
