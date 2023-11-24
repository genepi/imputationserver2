process CALCULATE_CHUNKS {

    tag "${vcf_file}"

    input:
    tuple val(chr), val(start), val(end), file(vcf_file),  file(info_file),  file(empirical_vcf_file)
    path(scores)

    output:
    path "*.txt", emit: scores_chunks
    path "*.info", emit: info_chunks

    script:
    name = "${vcf_file.baseName}_${chr}_${start}_${end}"

    """
    pgs-calc apply ${vcf_file} \
        --ref ${scores.join(',')} \
        --out ${name}.scores.txt \
        --info ${name}.scores.info \
        --start ${start} \
        --end ${end} \
        ${params.pgs.fix_strand_flips ? "--fix-strand-flips" : ""} \
        --min-r2 ${params.pgs.min_r2} \
        --no-ansi
    """

}