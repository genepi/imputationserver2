import groovy.json.JsonOutput

process COMPRESSION_ENCRYPTION {

  publishDir params.output, mode: 'copy'
  tag "Merge Chromosome ${chr}"

  input:
    tuple val(chr), path(imputed_vcf_header), path(imputed_vcf_data), path(imputed_info), path(imputed_meta_vcf_header), path(imputed_meta_vcf_data)
  output:
    path("*.zip"), emit: encrypted_files

  script:
    """

    # TODO: fix encryption to work with files out of the box
    mkdir chunks
    mkdir chunks/${chr}
    mv *.vcf.gz chunks/${chr}
    mv *.info chunks/${chr}

    java -jar /opt/imputationserver-utils/imputationserver-utils.jar \
      encrypt \
      --input chunks \
      --phasing ${params.phasing} \
      --aesEncryption ${params.aesEncryption} \
      --meta ${params.meta} \
      --reference ${params.refpanel.id} \
      --mode ${params.mode} \
      --password ${params.encryption_password} \
      --report cloudgene.report.json \
      --output ./

    """

}
