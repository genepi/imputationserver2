process MINIMAC4 {

  tag "${chunkfile}"

    input:
    tuple val(chr), val(start), val(end), val(phasing_status), path(chunkfile), path(m3vcf)
    path minimac_map
    val refpanel_build
    val minimac_window
    val minimac_min_ratio
    val min_r2
    val decay
    val diffThreshold
    val probThreshold
    output:
    tuple val(chr), val(start), val(end), file("*.dose.vcf.gz"), file("*.info.gz"), file("*.empiricalDose.vcf.gz"), emit: imputed_chunks

    script:
    def map = minimac_map ? '--map ' + minimac_map : ''
    def r2_filter = min_r2 != 0 ? '--min-r2 ' + min_r2 : ''
    def diff_threshold = diffThreshold != -1 ? '--diff-threshold ' + diffThreshold : ''
    def prob_threshold = probThreshold != -1 ? '--prob-threshold ' + probThreshold : ''
    def chunkfile_name = chunkfile.toString().replaceAll('.vcf.gz', '')
    def chr_cleaned = chr.startsWith('X.') ? 'X' : chr
    def chr_mapped = (refpanel_build == 'hg38') ? 'chr' + chr_cleaned : chr_cleaned

    """
    tabix ${chunkfile}

    minimac4 \
        --region $chr_mapped:$start-$end \
        --overlap $minimac_window \
        --output ${chunkfile_name}.dose.vcf.gz \
        --output-format vcf.gz \
        --format GT,DS,GP,HDS \
        --min-ratio $minimac_min_ratio \
        --all-typed-sites \
        --sites ${chunkfile_name}.info.gz \
        --empirical-output ${chunkfile_name}.empiricalDose.vcf.gz \
        --threads ${task.cpus} \
        --decay $decay \
        $diff_threshold \
        $prob_threshold \
        $r2_filter \
        $map \
        ${m3vcf} \
        ${chunkfile}
    """
}