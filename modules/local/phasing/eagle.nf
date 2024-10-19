process EAGLE {
    
    label 'phasing'
    tag "${chunkfile}"
    
    input:
    tuple val(chr), path(bcf), path(bcf_csi), val(start), val(end), val(phasing_status), path(chunkfile)
    path map_eagle

    output:
    tuple val(chr), val(start), val(end), val(phasing_status), file("*.phased.vcf.gz"), emit: eagle_phased_ch

    script:
    //define basename without ending (do not use simpleName due to X.*)
    def chunkfile_name = chunkfile.toString().replaceAll('.vcf.gz', '')
    // replace X.nonPAR etc with X for phasing
    def chr_cleaned = chr.startsWith('X.') ? 'X' : chr
    def chr_mapped = params.refpanel.build == 'hg38' ? 'chr' + chr_cleaned : chr_cleaned
    def phasing_start = start.toLong() - params.phasing.window
    phasing_start = phasing_start < 0 ? 1 : phasing_start
    def phasing_end = end.toLong() + params.phasing.window
    def num_threads = "nproc".execute().text.trim()
    """
    tabix $chunkfile
    eagle \
        --vcfRef ${bcf}  \
        --vcfTarget ${chunkfile} \
        --geneticMapFile ${map_eagle} \
        --outPrefix ${chunkfile_name}.phased \
        --chrom $chr_mapped \
        --bpStart $phasing_start \
        --bpEnd $phasing_end \
        --allowRefAltSwap \
        --vcfOutFormat z \
        --keepMissingPloidyX \
        --numThreads $num_threads
    """
}
