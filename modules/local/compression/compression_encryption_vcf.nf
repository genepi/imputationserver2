import groovy.json.JsonOutput

process COMPRESSION_ENCRYPTION_VCF {
    label 'postprocessing'
    publishDir params.output, mode: 'copy'
    tag "Merge Chromosome ${chr}"

    input:
    tuple val(chr), val(start), val(end), path(imputed_vcf_data), path(imputed_info), path(imputed_meta_vcf_data)

    output:
    path("final_vcf/*.dose.vcf.gz"), emit: dosage_vcf
    path("final_vcf/*.empiricalDose.vcf.gz"), emit: meta_vcf, optional: true
    path("*.zip"), emit: encrypted_file, optional: true
    path("*.md5"), emit: md5_file, optional: true
    path("chr${chr}*"), emit: raw_files, optional: true

    script:
    def imputed_joined = ArrayUtil.sort(imputed_vcf_data)
    def meta_joined = ArrayUtil.sort(imputed_meta_vcf_data)
    def prefix = "chr${chr}"
    def imputed_name = "${prefix}.dose.vcf.gz"
    def meta_name = "${prefix}.empiricalDose.vcf.gz"
    def zip_name = "chr_${chr}.zip"
    def aes = params.encryption.aes ? '-mem=AES256' : ''
    def panel_version = params.refpanel.id

    """
    # Create final_vcf directory
    mkdir -p final_vcf

    # Concatenate dosage VCF files and write to final_vcf/
    bcftools concat --threads ${task.cpus} -n ${imputed_joined} -o final_vcf/${imputed_name} -Oz

    # Write meta VCF files to final_vcf/ if meta processing is enabled
    if [[ "${params.imputation.meta}" == "true" ]]
    then
        bcftools concat --threads ${task.cpus} -n ${meta_joined} -o final_vcf/${meta_name} -Oz
        tabix final_vcf/${meta_name}
    fi

    # Create tabix index for imputed VCF if indexing is enabled
    if [[ "${params.imputation.create_index}" == "true" ]]
    then
        tabix final_vcf/${imputed_name}
    fi

    # Create MD5 checksum for the imputed VCF file if encryption is disabled and MD5 is enabled
    if [[ "${params.encryption.enabled}" == "false" && "${params.imputation.md5}" == "true" ]]
    then
        md5sum final_vcf/${imputed_name} > final_vcf/${imputed_name}.md5
    fi
    """
}
