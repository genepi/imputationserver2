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
    def meta_name = "${prefix}.empiricalDose.vcf.gz"
    def zip_name = "chr_${chr}.zip"
    def info_name = "${prefix}.info"
    def aes = params.encryption.aes ? "-mem=AES256" : ""
    def panel_version = RefPanelUtil.loadFromFile(params.refpanel_yaml).id
    
    """  
    # concat info files 
    csvtk concat ${info_joined} > ${info_name}
    bgzip ${info_name}
    
    # concat dosage files and update header 
    bcftools concat -n ${imputed_joined} -o tmp_${imputed_name} -Oz
    echo "##mis_pipeline=${params.pipeline_version}" > add_header.txt
    echo "##mis_phasing=${params.phasing}" >> add_header.txt
    echo "##mis_panel=${panel_version}" >> add_header.txt
    bcftools annotate -h add_header.txt tmp_${imputed_name} -o ${imputed_name} -Oz
    rm tmp_${imputed_name}
    tabix ${imputed_name}

    # write meta files
    if [[ ${params.meta} ]]
    then
        bcftools concat -n ${meta_joined} -o ${meta_name} -Oz
        tabix ${meta_name}
    fi

    # zip files
    7z a -tzip ${aes} -p"${params.encryption_password}" ${zip_name} ${prefix}*
    rm *vcf.gz* *info

    if [[ ${params.md5} ]]
    then
        md5sum ${zip_name} > ${zip_name}.md5
    fi
    """
 
}
