import groovy.json.JsonOutput

process EXECUTE_TRACE {

    input:
    path(samples)
    path(vcf_file)
    path(reference_site)
    path(reference_range)
    path(reference_geno)
    path(reference_pc_coord)
    path(reference_samples)

    output:
    path ("${batch_name}.ProPC.coord"), emit:  pcs

    script:
    batch_name = "batch_${samples.baseName}"

    """
    # extract samples form vcf
    bcftools view --samples-file ${samples} -Oz ${vcf_file} > ${batch_name}.vcf.gz
    tabix ${batch_name}.vcf.gz

    # convert to geno. TODO: check peopleIncludeFile option instead of bcftools.
    vcf2geno --inVcf ${batch_name}.vcf.gz --rangeFile ${reference_range} --out ${batch_name}

    # write config file for trace
    echo "GENO_FILE ${reference_geno}" > trace.config
    echo "STUDY_FILE ${batch_name}.geno" >> trace.config
    echo "COORD_FILE ${reference_pc_coord}" >> trace.config
    echo "DIM ${params.ancestry.dim}" >> trace.config
    echo "DIM_HIGH ${params.ancestry.dim_high}" >> trace.config
    echo "OUT_PREFIX ${batch_name}" >> trace.config

    # execute trace with config file
    trace -p trace.config > trace.log
    """

}
