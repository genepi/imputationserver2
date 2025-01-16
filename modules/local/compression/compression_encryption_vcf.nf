import groovy.json.JsonOutput

process COMPRESSION_ENCRYPTION_VCF {
    
    label 'postprocessing'
    publishDir params.output, mode: 'copy'
    tag "Merge Chromosome ${chr}"

    input:
    tuple val(chr), val(start), val(end), path(imputed_vcf_data), path(imputed_info), path(imputed_meta_vcf_data)
    
    output:
    path("*.zip"), emit: encrypted_file, optional: true
    path("*.md5"), emit: md5_file, optional: true
    path("chr${chr}*"), emit: raw_files, optional: true
    
    script:
    def imputed_joined = ArrayUtil.sort(imputed_vcf_data)
    def meta_joined = ArrayUtil.sort(imputed_meta_vcf_data)
    def info_joined = ArrayUtil.sort(imputed_info)
    def prefix = "chr${chr}"
    def imputed_name = "${prefix}.dose.vcf.gz"
    def meta_name = "${prefix}.empiricalDose.vcf.gz"
    def zip_name = "chr_${chr}.zip"
    def info_name = "${prefix}.info.gz"
    def aes = params.encryption.aes ? "-mem=AES256" : ""
    def panel_version = params.refpanel.id
    
    """  
    # concat info files 
    bcftools concat --threads ${task.cpus} -n ${info_joined} -o ${info_name} -Oz
    
    # concat dosage files and update header 
    bcftools concat --threads ${task.cpus} -n ${imputed_joined} -o intermediate_${imputed_name} -Oz
    echo "##mis_pipeline=${workflow.manifest.version}" > add_header.txt
    echo "##mis_phasing=${params.phasing.engine}" >> add_header.txt
    echo "##mis_panel=${panel_version}" >> add_header.txt
    bcftools annotate --threads ${task.cpus} -h add_header.txt intermediate_${imputed_name} -o ${imputed_name} -Oz
    rm intermediate_${imputed_name}

    # write meta files
    if [[ "${params.imputation.meta}" = true ]]
    then
        bcftools concat --threads ${task.cpus} -n ${meta_joined} -o ${meta_name} -Oz
        tabix ${meta_name}
    fi

    # create tabix files
    if [[ "${params.imputation.create_index}" = true ]]
    then
        tabix ${imputed_name}
    fi    
  
    # zip files
    if [[ "${params.encryption.enabled}" = true ]]
    then    
        7z a -tzip ${aes} -mmt${task.cpus} -p"${params.encryption_password}" ${zip_name} ${prefix}*
        rm *vcf.gz* *info.gz add_header.txt
    fi
    
    # create md5 of zip file
    if [[ "${params.encryption.enabled}" = true && "${params.imputation.md5}" = true ]]
    then
        md5sum ${zip_name} > ${zip_name}.md5
    fi

    # create md5 of imputed file
    if [[ "${params.encryption.enabled}" = false && "${params.imputation.md5}" = true ]]
    then
        md5sum ${imputed_name} > ${imputed_name}.md5
    fi

    """ 
}
