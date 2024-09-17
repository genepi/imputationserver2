process QUALITY_CONTROL_REPORT {
    
    label 'preprocessing'
    publishDir params.output, mode: 'copy'

    input:
    path(maf_file)
    path(validation_report)
    path(qc_report)
    path(qc_report_file)

    output:
    path("*.html")

    script:
    """
    Rscript -e "require( 'rmarkdown' ); render('${qc_report_file}',
        params = list(
            maf_file = '${maf_file}',
            validation_report = '${validation_report}',
            qc_report = '${qc_report}',
            name = '${params.project}',
            allele_frequency_population = '${params.population}',
            version = '${workflow.manifest.version}',
            date = '${params.project_date}',
            service = '${params.service.name}'
        ),
        intermediates_dir='\$PWD',
        knit_root_dir='\$PWD',
        output_file='\$PWD/quality-control.html'
    )"
    """

}
