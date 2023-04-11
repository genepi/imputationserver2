import groovy.json.JsonOutput

process COMPRESSION_ENCRYPTION {

  publishDir params.output, mode: 'copy'
  tag "Merge Chromosome ${chr}"

  input:
     tuple val(chr), path(imputed_vcf_header), path(imputed_vcf_data), path(imputed_info), path(imputed_meta_vcf_header), path(imputed_meta_vcf_data)

  output:
    path("*.zip"), emit: encrypted_files

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
            //TODO: add meta
            //TODO: add aesEncryption
            //TODO: localOutput not set. current folder?
            outputimputation: 'chunks',
            password: params.password
        ],
        data: [
            refpanel: params.refpanel
        ]
    ]

    """
    echo '${JsonOutput.toJson(config)}' > config.json

    mkdir chunks
    mkdir chunks/${chr}
    mv *.vcf.gz chunks/${chr}
    mv *.info chunks/${chr}

    java -cp /opt/imputationserver-utils/imputationserver-utils.jar \
      cloudgene.sdk.weblog.WebLogRunner \
      genepi.imputationserver.steps.CompressionEncryption \
      config.json \
      05-compression-encryption.log

    """

}
