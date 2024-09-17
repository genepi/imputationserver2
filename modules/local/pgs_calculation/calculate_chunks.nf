process CALCULATE_CHUNKS {
    
    label 'pgs'
    tag "${vcf_file}"

    input:
    tuple val(chr), val(start), val(end), path(vcf_file),  path(info_file),  path(empirical_vcf_file)
    tuple(path(scores_txt), path(scores_info), path(scores_index))
    path(scores)

    output:
    path "*.txt", emit: scores_chunks
    path "*.info", emit: info_chunks

    script:
    name = "${vcf_file.baseName}_${chr}_${start}_${end}"
    def avail_mem = 1024
    if (!task.memory) {
        log.info '[CALCULATE_CHUNKS] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    java -Xmx${avail_mem}M -jar /opt/pgs-calc/pgs-calc.jar \
        apply ${vcf_file} \
        --ref ${scores_txt} \
        --out ${name}.scores.txt \
        --include-scores ${scores} \
        --info ${name}.scores.info \
        --start ${start} \
        --end ${end} \
        ${params.pgs.fix_strand_flips ? "--fix-strand-flips" : ""} \
        --min-r2 ${params.pgs.min_r2} \
        --no-ansi
    """

}