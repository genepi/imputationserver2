process BEAGLE {

    label 'phasing'
    tag "${chunkfile}"

    input:
    tuple val(chr), path(bcf), val(start), val(end), val(phasing_status), path(chunkfile), path(map_beagle)

    output:
    tuple val(chr), val(start), val(end), val(phasing_status), file("*.phased.vcf.gz"), emit: beagle_phased_ch

    script:
    // Define basename without ending (do not use simpleName due to X.*)
    def chunkfile_name = chunkfile.toString().replaceAll('.vcf.gz', '')
    // Replace X.nonPAR etc. with X for phasing
    def chr_cleaned = chr.startsWith('X.') ? 'X' : chr
    def chr_mapped = params.refpanel.build == 'hg38' ? 'chr' + chr_cleaned : chr_cleaned
    def phasing_start = start.toLong() - params.phasing.window
    phasing_start = phasing_start < 0 ? 1 : phasing_start
    def phasing_end = end.toLong() + params.phasing.window
    def num_threads = "nproc".execute().text.trim()

    // Set impute parameter based on params.phasing.impute
    def impute_param = params.phasing.impute ? 'true' : 'false'

    """
    java -jar /usr/bin/beagle.27May24.118.jar \\
        ref=${bcf}  \\
        gt=${chunkfile} \\
        out=${chunkfile_name}.phased \\
        nthreads=$num_threads \\
        chrom=${chr_mapped}:${phasing_start}-${phasing_end} \\
        map=${map_beagle} \\
        impute=${impute_param}
    """
}
