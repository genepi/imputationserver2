import groovy.json.JsonOutput

process INPUT_VALIDATION {

  input:
    path(vcf_file)

  output:
    path("*.vcf.gz"), includeInputs: true, emit: validated_files

  script:

    config = [
        inputs: ['files'],
        params: [
            files: './',
            population: params.population,
            phasing: params.phasing,
            refpanel: params.refpanel.id,
            build: params.build,
            mode: params.mode
            //TODO: add missing params?
        ],
        data: [
            refpanel: params.refpanel
        ]
    ]

    """
    echo '${JsonOutput.toJson(config)}' > config.json

    java -cp /opt/imputationserver-utils/imputationserver-utils.jar \
      cloudgene.sdk.weblog.WebLogRunner \
      genepi.imputationserver.steps.InputValidation \
      config.json \
      01-input-validation.log

    """

}
