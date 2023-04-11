process IMPUTATION {

  tag "${chunkfile}"

  input:
    tuple val(chr), val(start), val(end), val(phasing_status), path(chunkfile), path(m3vcf)
    path minimac_map
    val phasing_method

  output:
     tuple val(chr), file("*.header.dose.vcf.gz"), file("*.data.dose.vcf.gz"), file("*.info"), file("*.header.empiricalDose.vcf.gz"), file("*.data.empiricalDose.vcf.gz"), emit: imputed_chunks

 script:
   def map = minimac_map.name != 'NO_MAP_FILE' ? '--referenceEstimates --map ' + mapMinimac : ''
   //define basename without ending (do not use simpleName due to X.*)
   def chunkfile_name = "$chunkfile".replaceAll('.vcf.gz', '')
   // replace X.nonPAR etc with X for minimac4
   def chr_cleaned = "${chr}".startsWith('X.') ? 'X' : "${chr}"
   def chr_mapped = "${params.reference_build}" == 'hg38' ? 'chr' + "${chr_cleaned}" : "${chr_cleaned}"
   def phasing_method  = "${phasing_status}" == 'VCF-PHASED' ? 'n/a' : "${phasing_method}"
   def isChrM = "${chr}" == 'MT' ? '--myChromosome ' + "${chr}" : ''

  """
  minimac4 \
   --refHaps ${m3vcf} \
   --haps ${chunkfile} \
   --start $start \
   --end $end \
   --window ${params.minimac_window} \
   --prefix ${chunkfile_name} \
   --cpus ${params.cpus} \
   --chr $chr_mapped \
   $isChrM \
   --noPhoneHome \
   --format GT,DS,GP \
   --allTypedSites \
   --meta \
   --minRatio ${params.minimac_min_ratio} \
   $map

   # write software versions to headers
   bcftools view ${chunkfile_name}.dose.vcf.gz | bcftools view -h > ${chunkfile_name}.header
   bcftools view ${chunkfile_name}.empiricalDose.vcf.gz | bcftools view -h > ${chunkfile_name}.empiricalDose.header
   sed '/^#CHROM.*/i ##pipeline=${params.pipeline_version}\\n##imputation=${params.imputation_version}\\n##phasing=${phasing_method}\\n##panel=${params.id}\\n##r2Filter=${params.r2Filter}' ${chunkfile_name}.header | bgzip > ${chunkfile_name}.header.dose.vcf.gz
   sed '/^#CHROM.*/i ##pipeline=${params.pipeline_version}\\n##imputation=${params.imputation_version}\\n##phasing=${phasing_method}\\n##panel=${params.id}\\n##r2Filter=${params.r2Filter}' ${chunkfile_name}.empiricalDose.header | bgzip > ${chunkfile_name}.header.empiricalDose.vcf.gz

   # apply R2 filter
   if [[ ${params.r2Filter} > 0 ]]
   then
     # filter info file
     mv ${chunkfile_name}.info ${chunkfile_name}.info.tmp
     awk '{ if (\$7 > ${params.r2Filter}) print \$0 }' ${chunkfile_name}.info.tmp  > ${chunkfile_name}.info
     rm ${chunkfile_name}.info.tmp
     # filter dosage files
     bcftools filter -i 'R2>${params.r2Filter}' ${chunkfile_name}.dose.vcf.gz | bcftools view -H | bgzip > ${chunkfile_name}.data.dose.vcf.gz
     bcftools filter -i 'R2>${params.r2Filter}' ${chunkfile_name}.empiricalDose.vcf.gz | bcftools view -H | bgzip > ${chunkfile_name}.data.empiricalDose.vcf.gz
   else
     bcftools view ${chunkfile_name}.dose.vcf.gz -H | bgzip > ${chunkfile_name}.data.dose.vcf.gz
     bcftools view ${chunkfile_name}.empiricalDose.vcf.gz -H | bgzip > ${chunkfile_name}.data.empiricalDose.vcf.gz
   fi

   # delete files
   rm ${chunkfile_name}.dose.vcf.gz
   rm ${chunkfile_name}.empiricalDose.vcf.gz

  """
}
