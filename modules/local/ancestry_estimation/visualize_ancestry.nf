import groovy.json.JsonOutput

process VISUALIZE_ANCESTRY {

    publishDir params.output, mode: 'copy'

    input:
    path(ancestry_estimation_report)
    path(estimated_ancestry)
    path(reference_pc_coord)
    path(reference_samples)

    output:
    path ("*.html")

    script:

    """
    # create PCA plot
    Rscript -e "require( 'rmarkdown' ); render('${ancestry_estimation_report}',
        params = list(
            populations = '${estimated_ancestry}',
            reference_pc_coord = '${reference_pc_coord}',
            reference_samples = '${reference_samples}'
        ),
        intermediates_dir='\$PWD',
        knit_root_dir='\$PWD',
        output_file='\$PWD/estimated-populations.html'
    )"
    """

}
