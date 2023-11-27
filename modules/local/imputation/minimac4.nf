process MINIMAC4 {

  tag "${chunkfile}"

    input:
    tuple val(chr), val(start), val(end), val(phasing_status), path(chunkfile), path(m3vcf)
    path minimac_map

    output:
    tuple val(chr), val(start), val(end), file("*.dose.vcf.gz"), file("*.info"), file("*.empiricalDose.vcf.gz"), emit: imputed_chunks

    script:
    def map = minimac_map ? '--referenceEstimates --map ' + minimac_map : ''
    def chunkfile_name = "${chunkfile}".replaceAll('.vcf.gz', '')
    def chr_cleaned = "${chr}".startsWith('X.') ? 'X' : "${chr}"
    def chr_mapped = "${params.refpanel.build}" == 'hg38' ? 'chr' + "${chr_cleaned}" : "${chr_cleaned}"
    def isChrM = "${chr}" == 'MT' ? '--myChromosome ' + "${chr}" : ''

    """
    minimac4 \
        --refHaps ${m3vcf} \
        --haps ${chunkfile} \
        --start $start \
        --end $end \
        --window ${params.minimac_window} \
        --prefix ${chunkfile_name} \
        --cpus ${task.cpus} \
        --chr $chr_mapped \
        $isChrM \
        --noPhoneHome \
        --format GT,DS,GP \
        --allTypedSites \
        --meta \
        --minRatio ${params.minimac_min_ratio} \
        $map

     # apply R2 filter
   if [[ ${params.r2Filter} > 0 ]]
   then
       
       # filter info file
       csvtk filter --num-cpus ${task.cpus} ${chunkfile_name}.info -f "Rsq>${params.r2Filter}" -t > ${chunkfile_name}.filtered.info
       rm ${chunkfile_name}.info

       # filter dosage files
       bcftools filter --threads ${task.cpus} -i 'INFO/R2>${params.r2Filter}' ${chunkfile_name}.dose.vcf.gz -o ${chunkfile_name}.data.dose.vcf.gz -Oz 
       rm ${chunkfile_name}.dose.vcf.gz 
   fi
   
  """
  
}
