process NO_PHASING {

    tag "${chunk_file}"

    input:
    tuple val(chr), val(start), val(end), val(phasing_status), path(chunk_file), val(snps), val(in_reference)

    output:
    tuple val(chr), val(start), val(end), val(phasing_status), file("${chunk_file.simpleName}.phased.vcf.gz"), emit: skipped_phasing_ch

    script:
    if( phasing_status == 'VCF-PHASED' ) {
    """
    mv ${chunk_file} ${chunk_file.simpleName}.phased.vcf.gz
    """
    }
    else {
    error "Invalid phasing status: ${phasing_status}"
    }
   
}
