process MINIMAC4 {

    label 'imputation'
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
    val probThresholdS1
    val minRecombination
    output:
    tuple val(chr), val(start), val(end), file("*.dose.vcf.gz"), file("*.info.gz"), file("*.empiricalDose.vcf.gz"), emit: imputed_chunks

    script:
    def map = minimac_map ? '--map ' + minimac_map : ''
    def r2_filter = min_r2 != 0 ? '--min-r2 ' + min_r2 : ''
    def diff_threshold = diffThreshold != -1 ? '--diff-threshold ' + diffThreshold : ''
    def prob_threshold = probThreshold != -1 ? '--prob-threshold ' + probThreshold : ''
    def prob_threshold_s1 = probThresholdS1 != -1 ? '--prob-threshold-s1 ' + probThresholdS1 : ''
    def min_recom = minRecombination != -1 ? '--min-recom ' + minRecombination : ''
    def chunkfile_name = chunkfile.toString().replaceAll('.vcf.gz', '')
    def chr_cleaned = chr.startsWith('X.') ? 'X' : chr
    def chr_mapped = (refpanel_build == 'hg38') ? 'chr' + chr_cleaned : chr_cleaned
    def used_threads = params.service.threads != -1 ? params.service.threads : task.cpus

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
        --threads $used_threads \
        --decay $decay \
        --temp-prefix ./ \
        $diff_threshold \
        $prob_threshold \
        $prob_threshold_s1 \
        $min_recom \
        $r2_filter \
        $map \
        ${m3vcf} \
        ${chunkfile}
    """
}