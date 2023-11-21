process MINIMAC4 {

  tag "${chunkfile}"

    input:
    tuple val(chr), val(start), val(end), val(phasing_status), path(chunkfile), path(m3vcf)
    path minimac_map

    output:
    tuple val(chr), val(start), val(end), file("*.dose.vcf.gz"), file("*.info"), file("*.empiricalDose.vcf.gz"), emit: imputed_chunks

    script:
    def map = minimac_map ? '--referenceEstimates --map ' + minimac_map : ''
    //define basename without ending (do not use simpleName due to X.*)
    def chunkfile_name = "$chunkfile".replaceAll('.vcf.gz', '')
    // replace X.nonPAR etc with X for minimac4
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
        --cpus ${params.cpus} \
        --chr $chr_mapped \
        $isChrM \
        --noPhoneHome \
        --format GT,DS,GP \
        --allTypedSites \
        --meta \
        --minRatio ${params.minimac_min_ratio} \
        $map
  """
  
}
