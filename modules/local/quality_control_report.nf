import groovy.json.JsonOutput

process QUALITY_CONTROL_REPORT {

  publishDir params.output, mode: 'copy'

  input:
    path(maf_file)
    path(qc_report)

  output:
    path("*.html")

  script:
    """
    # TODO: switch to param. report (see nf-gwas) and move it on reports folder.
    Rscript -e "require( 'rmarkdown' ); render('${qc_report}',
        params = list(
        ),
        intermediates_dir='\$PWD',
        knit_root_dir='\$PWD',
        output_file='\$PWD/03-quality-control-report.html'
      )" \
      ${maf_file}

    """

}
