import groovy.json.JsonOutput

process INPUT_VALIDATION_VCF {

  publishDir params.output, mode: 'copy', pattern: '*.{html,log}'
  memory = { 1.GB }
  input:
    path(vcf_files)

  output:
    path("*.vcf.gz"), includeInputs: true, emit: validated_files

  script:
    """
    echo '${JsonOutput.toJson(params.refpanel)}' > reference-panel.json

    # TODO: add params.min_samples and params.max_samples, contact, mail, ...
    java -Xmx16G -jar /opt/imputationserver-utils/imputationserver-utils.jar \
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
