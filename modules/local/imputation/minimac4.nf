process MINIMAC4 {

  tag "${chunkfile}"

    input:
    tuple val(chr), val(start), val(end), val(phasing_status), path(chunkfile), path(m3vcf)
    path minimac_map

    output:
    tuple val(chr), val(start), val(end), file("*.dose.vcf.gz"), file("*.info.gz"), file("*.empiricalDose.vcf.gz"), emit: imputed_chunks

    script:
    def map = minimac_map ? '--map ' + minimac_map : ''
    def chunkfile_name = chunkfile.toString().replaceAll('.vcf.gz', '')
    def chr_cleaned = chr.startsWith('X.') ? 'X' : chr
    def chr_mapped = (params.refpanel.build == 'hg38') ? 'chr' + chr_cleaned : chr_cleaned

    """
    tabix ${chunkfile}

    minimac4 \
        --region $chr_mapped:$start-$end \
        --overlap ${params.minimac_window} \
        --output ${chunkfile_name}.dose.vcf.gz \
        --output-format vcf.gz \
        --format GT,DS,GP \
        --min-ratio 0.00001 \
        --all-typed-sites \
        --min-r2 ${params.r2Filter} \
        --sites ${chunkfile_name}.info.gz \
        --empirical-output ${chunkfile_name}.empiricalDose.vcf.gz \
        --threads ${task.cpus} \
        $map \
        ${m3vcf} \
        ${chunkfile}
    """
}
