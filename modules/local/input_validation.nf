import groovy.json.JsonOutput

process INPUT_VALIDATION {

  publishDir params.output, mode: 'copy', pattern: '*.{html,log}'

  input:
    path(vcf_files)

  output:
    path("*.vcf.gz"), includeInputs: true, emit: validated_files

  script:

    println task.process

    """
    echo '${JsonOutput.toJson(params.refpanel)}' > reference-panel.json

    java -jar /opt/imputationserver-utils/imputationserver-utils.jar \
      validate \
      --population ${params.population} \
      --phasing ${params.phasing} \
      --reference reference-panel.json \
      --build ${params.build} \
      --mode ${params.mode} \
      --report cloudgene.report.json \
       $vcf_files 

    """

  }
