import groovy.json.JsonOutput

process COMPRESSION_ENCRYPTION_VCF {

    publishDir params.output, mode: 'copy'
    tag "Merge Chromosome ${chr}"

    input:
    tuple val(chr), path(imputed_vcf_data), path(imputed_info), path(imputed_meta_vcf_data)
    
    output:
    path("*.zip"), emit: encrypted_file
    path("*.md5"), emit: md5_file
    script:
    def imputed_joined = Manipulations.sortValues(imputed_vcf_data)
    def meta_joined = Manipulations.sortValues(imputed_meta_vcf_data)
    def info_joined = Manipulations.sortValues(imputed_info)
    """
    imputed_name=chr${chr}.dose.vcf.gz
    meta_name=chr${chr}_empiricalDose.vcf.gz
    zip_name=chr_${chr}.zip
    info_name=chr${chr}.info
    bcftools concat -n ${imputed_joined} -o \$imputed_name -Oz
    tabix \$imputed_name
    bcftools concat -n ${meta_joined} -o \$meta_name -Oz
    tabix \$meta_name
    csvtk concat ${info_joined} > \$info_name
    bgzip \$info_name
    7z a -tzip -p${params.encryption_password} \$zip_name  \$imputed_name* \$meta_name* \$info_name.gz
    md5sum \$zip_name > ${chr}.md5
    """
}

