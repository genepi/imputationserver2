import groovy.json.JsonOutput

process QUALITY_CONTROL_VCF {


    //TODO remove for cloudgene
    publishDir params.output, mode: 'copy', pattern: "*.json"
    publishDir params.output, mode: 'copy', pattern: "${statisticsDir}/*.txt"

    input:
    path(vcf_files)
    path(legend_files)

    output:
    path("${metaFilesDir}/*"), emit: chunks_csv
    path("${chunksDir}/*"), emit: chunks_vcf
    path("${statisticsDir}/*")
    path("maf.txt", emit: maf_file)
    path("cloudgene.report.json")

    script:

    chunksDir = 'chunks'
    metaFilesDir = 'metafiles'
    statisticsDir = 'statistics'
    mafFile = 'maf.txt'

    """
    echo '${JsonOutput.toJson(params.refpanel)}' > reference-panel.json

    # TODO: create directories in java
    mkdir ${chunksDir}
    mkdir ${metaFilesDir}
    mkdir ${statisticsDir}
  
    # TODO: add lifover and set chain directory
    java -jar /opt/imputationserver-utils/imputationserver-utils.jar \
      run-qc \
      --population ${params.population} \
      --reference reference-panel.json \
      --build ${params.build} \
      --maf-output ${mafFile} \
      --phasing-window ${params.phasing_window} \
      --chunksize ${params.chunksize} \
      --chunks-out ${chunksDir} \
      --statistics-out ${statisticsDir} \
      --metafiles-out ${metaFilesDir} \
      --report cloudgene.report.json \
       $vcf_files 
    """

}
