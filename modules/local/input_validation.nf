import groovy.json.JsonOutput

process INPUT_VALIDATION {

  publishDir params.output, mode: 'copy', pattern: '*.{html,log}'

  input:
    path(vcf_files)

  output:
    path("*.vcf.gz"), includeInputs: true, emit: validated_files
    path("*.html")

  script:

    println task.process

    """
    echo '${JsonOutput.toJson(params.refpanel)}' > config.json

    java -jar /opt/imputationserver-utils/imputationserver-utils.jar \
      validate \
      --population ${params.population} \
      --phasing ${params.phasing} \
      --reference config.json \
      --build ${params.build} \
      --mode ${params.mode} \
      --output cloudgene.log \
       $vcf_files 


      ccat cloudgene.log --html > 01-input-validation.html

    """

  }
