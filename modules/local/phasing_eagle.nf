process PHASING_EAGLE {

  tag "${chunkfile}"

  input:
    tuple val(chr), path(bcf), path(bcf_csi), val(start), val(end), val(phasing_status), path(chunkfile), val(snps), val(in_reference)
    path map_eagle
    val phasing_method

  output:
   tuple val(chr), val(start), val(end), val(phasing_status), file("*.phased.vcf.gz"), emit: eagle_phased_ch
   path "*.header.dose.vcf.gz", optional: true
   path "*.phased.vcf.gz", optional: true

  script:
   def phasing_method  = "${phasing_status}" == 'VCF-PHASED' ? 'n/a' : "${phasing_method}"
   //define basename without ending (do not use simpleName due to X.*)
   def chunkfile_name = "$chunkfile".replaceAll('.vcf.gz', '')
   // replace X.nonPAR etc with X for phasing
   def chr_cleaned = "${chr}".startsWith('X.') ? 'X' : "${chr}"
   def chr_mapped = "${params.reference_build}" == 'hg38' ? 'chr' + "${chr_cleaned}" : "${chr_cleaned}"
   def phasing_post_processing =
   """
   if [[ "${params.mode}" == 'phasing' ]]
   then
    mv ${chunkfile_name}.phased.vcf.gz ${chunkfile_name}.phased.tmp.vcf.gz
    tabix ${chunkfile_name}.phased.tmp.vcf.gz
    bcftools view ${chunkfile_name}.phased.tmp.vcf.gz -r$chr_mapped:$start-$end -H | bgzip > ${chunkfile_name}.phased.vcf.gz
    bcftools view ${chunkfile_name}.phased.tmp.vcf.gz | bcftools view -h > ${chunkfile_name}.header
    sed '/^#CHROM.*/i ##pipeline=${params.pipeline_version}\\n##phasing=${phasing_method}\\n##panel=${params.id}\\n##r2Filter=${params.r2Filter}' ${chunkfile_name}.header | bgzip > ${chunkfile_name}.header.dose.vcf.gz
    rm ${chunkfile_name}.phased.tmp.vcf.gz
   fi
   """

   if( phasing_status == 'VCF-UNPHASED' ) {
    """
    tabix $chunkfile
     eagle \
     --vcfRef ${bcf}  \
     --vcfTarget ${chunkfile} \
     --geneticMapFile ${map_eagle} \
     --outPrefix ${chunkfile_name}.phased \
     --chrom $chr_mapped \
     --bpStart $start \
     --bpEnd $end \
     --allowRefAltSwap \
     --vcfOutFormat z \
     --keepMissingPloidyX

    # phasing only
    $phasing_post_processing
   """
   }
   else if( phasing_status == 'VCF-PHASED' ) {
    """
    mv ${chunkfile} ${chunkfile_name}.phased.vcf.gz

    # phasing only
    $phasing_post_processing
    """
   }
   else {
    error "Invalid phasing status: ${phasing_status}"
   }
}
