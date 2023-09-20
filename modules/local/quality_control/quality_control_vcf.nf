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
    path("${statisticsDir}/*"), optional: true
    path("maf.txt", emit: maf_file)
    path("cloudgene.report.json")

    script:
    chunksDir = 'chunks'
    metaFilesDir = 'metafiles'
    statisticsDir = 'statistics'
    mafFile = 'maf.txt'

    def avail_mem = 1024
    if (!task.memory) {
        log.info '[Quality Control VCF] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    echo '${JsonOutput.toJson(params.refpanel)}' > reference-panel.json

    # TODO: create directories in java
    mkdir ${chunksDir}
    mkdir ${metaFilesDir}
    mkdir ${statisticsDir}
  
    # TODO: add lifover and set chain directory
    java -Xmx${avail_mem}M -jar /opt/imputationserver-utils/imputationserver-utils.jar \
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
