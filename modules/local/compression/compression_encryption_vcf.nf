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
    def imputed = imputed_vcf_data as String[]
    def imputed_sorted = imputed.sort(false) { it.tokenize('_')[2] as Integer }
    def imputed_joined = imputed_sorted.join(" ")
    def meta_array = imputed_meta_vcf_data as String[]
    def meta_sorted = meta_array.sort(false) { it.tokenize('_')[2] as Integer }
    def meta_joined = meta_sorted.join(" ")
    """
    imputed_name=chr${chr}.dose.vcf.gz
    meta_name=chr${chr}_empiricalDose.vcf.gz
    zip_name=chr${chr}.zip
    bcftools concat -n ${imputed_joined} -o \$imputed_name -Oz
    tabix \$imputed_name
    bcftools concat -n ${meta_joined} -o \$meta_name -Oz
    tabix \$meta_name
    7z a -tzip -p${params.encryption_password} \$zip_name  \$imputed_name* \$meta_name*
    md5sum \$zip_name > ${chr}.md5
    """
}

