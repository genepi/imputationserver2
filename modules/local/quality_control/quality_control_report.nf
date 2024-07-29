process QUALITY_CONTROL_REPORT {

    publishDir params.output, mode: 'copy'

    input:
    path(maf_file)
    path(qc_result)
    path(qc_report)

    output:
    path("*.html")

    script:
    """
    Rscript -e "require( 'rmarkdown' ); render('${qc_report}',
        params = list(
            maf_file = '${maf_file}',
            qc_result = '${qc_result}',
            name = '${params.project}',
            population = '${params.population}',
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
