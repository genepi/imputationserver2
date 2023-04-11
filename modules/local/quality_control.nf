import groovy.json.JsonOutput

process QUALITY_CONTROL {

  input:
    path(vcf_file)
    path(legend_files)

  output:
    path("${config.params.chunkFileDir}/*"), emit: chunks_csv
    path("${config.params.chunksDir}/*"), emit: chunks_vcf
    path("maf.txt", emit: maf_file)

  script:

    config = [
        inputs: ['files'],
        params: [
            files: './',
            population: params.population,
            phasing: params.phasing,
            refpanel: params.refpanel.id,
            build: params.build,
            mode: params.mode,
            chunksDir: 'chunks',
            chunkFileDir: 'chunkfile',
            statisticsDir: 'statistics',
            mafFile: 'maf.txt'
        ],
        data: [
            refpanel: params.refpanel
        ]
    ]

    """
    echo '${JsonOutput.toJson(config)}' > config.json

    mkdir ${config.params.chunksDir}
    mkdir ${config.params.chunkFileDir}
    mkdir ${config.params.statisticsDir}

    java -cp /opt/imputationserver-utils/imputationserver-utils.jar \
      cloudgene.sdk.weblog.WebLogRunner \
      genepi.imputationserver.steps.FastQualityControl \
      config.json \
      02-quality-control.log
    """

}
