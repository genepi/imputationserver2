import groovy.json.JsonOutput

process COMPRESSION_ENCRYPTION_VCF {

    publishDir params.output, mode: 'copy'
    tag "Merge Chromosome ${chr}"

    input:
    tuple val(chr), val(start), val(end), path(imputed_vcf_data), path(imputed_info), path(imputed_meta_vcf_data)
    
    output:
    path("*.zip"), emit: encrypted_file
    path("*.md5"), emit: md5_file, optional: true
    
    script:
    def imputed_joined = ArrayUtil.sort(imputed_vcf_data)
    def meta_joined = ArrayUtil.sort(imputed_meta_vcf_data)
    def info_joined = ArrayUtil.sort(imputed_info)
    def prefix = "chr${chr}"
    def imputed_name = "${prefix}.dose.vcf.gz"
    def meta_name = "${prefix}_empiricalDose.vcf.gz"
    def zip_name = "chr_${chr}.zip"
    def info_name = "${prefix}.info"
    def aes = params.encryption.aes ? "-mem=AES256" : ""

    """  
    bcftools concat -n ${imputed_joined} -o ${imputed_name} -Oz
    tabix ${imputed_name}
    csvtk concat ${info_joined} > ${info_name}
    bgzip ${info_name}
    
    if [[ "${params.meta}" == "true" ]]
    then
        bcftools concat -n ${meta_joined} -o ${meta_name} -Oz
        tabix ${meta_name}
    fi

    7z a -tzip ${aes} -p"${params.encryption_password}" ${zip_name} ${prefix}*
    rm *vcf.gz* *info

    if [[ "${params.md5}" == "true" ]]
    then
        md5sum ${zip_name} > ${zip_name}.md5
    fi
    """
 
}
