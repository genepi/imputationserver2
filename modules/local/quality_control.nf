import groovy.json.JsonOutput

process QUALITY_CONTROL {

  publishDir params.output, mode: 'copy', pattern: '*.{html,log}'

  input:
    path(vcf_files)
    path(legend_files)

  output:
    path("${config.params.metaFilesDir}/*"), emit: chunks_csv
    path("${config.params.chunksDir}/*"), emit: chunks_vcf
    path("maf.txt", emit: maf_file)

  script:

    config = [
        params: [
            chunksDir: 'chunks',
            metaFilesDir: 'metafiles',
            statisticsDir: 'statistics',
            mafFile: 'maf.txt'
        ]
    ]

    """
    echo '${JsonOutput.toJson(params.refpanel)}' > reference-panel.json

    mkdir ${config.params.chunksDir}
    mkdir ${config.params.metaFilesDir}
    mkdir ${config.params.statisticsDir}
  
    java -jar /opt/imputationserver-utils/imputationserver-utils.jar \
      run-qc \
      --population ${params.population} \
      --reference reference-panel.json \
      --build ${params.build} \
      --maf-output ${config.params.mafFile} \
      --chunks-out ${config.params.chunksDir} \
      --statistics-out ${config.params.statisticsDir} \
      --metafiles-out ${config.params.metaFilesDir} \
      --report cloudgene.report.json \
       $vcf_files 
    """

}
