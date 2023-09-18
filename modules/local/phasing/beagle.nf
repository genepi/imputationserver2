process BEAGLE {

    tag "${chunkfile}"

    input:
    tuple val(chr), path(bcf), val(start), val(end), val(phasing_status), path(chunkfile), val(snps), val(in_reference),  path(map_beagle)
    val phasing_method

    output:
    tuple val(chr), val(start), val(end), val(phasing_status), file("*.phased.vcf.gz"), emit: beagle_phased_ch

    script:
    def phasing_method  = "${phasing_status}" == 'VCF-PHASED' ? 'n/a' : "${phasing_method}"
    //define basename without ending (do not use simpleName due to X.*)
    def chunkfile_name = "$chunkfile".replaceAll('.vcf.gz', '')
    // replace X.nonPAR etc with X for phasing
    def chr_cleaned = "${chr}".startsWith('X.') ? 'X' : "${chr}"
    def chr_mapped = "${params.refpanel.build}" == 'hg38' ? 'chr' + "${chr_cleaned}" : "${chr_cleaned}"
  
    """
    java -jar /usr/bin/beagle.18May20.d20.jar \
        ref=${bcf}  \
        gt=${chunkfile} \
        out=${chunkfile_name}.phased \
        nthreads=1 \
        chrom=${chr_mapped}:${start}-${end}  \
        map=${map_beagle} \
        impute=false

    """
}
