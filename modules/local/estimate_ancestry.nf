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

    config = [
        params: [
            samples: "${reference_samples}",
            reference_pc: "${reference_pc_coord}",
            study_pc: "study.ProPC.coord",
            max_pcs: "${params.ancestry.max_pcs}",
            k: "${params.ancestry.k}",
            threshold: "${params.ancestry.threshold}",
            output: "estimated-population.txt"
        ]
    ]

    """

    # merge csv files
    csvtk concat ${study_pcs} > study.ProPC.coord

    # run population predictor
    echo '${JsonOutput.toJson(config)}' > config.json

    java -cp /opt/imputationserver-utils/imputationserver-utils.jar \
      cloudgene.sdk.weblog.WebLogRunner \
      genepi.imputationserver.steps.PopulationPredictorStep \
      config.json \
      08-predict-population.log

    ccat 08-predict-population.log --html > 08-predict-population.html

    """

}
