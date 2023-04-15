import groovy.json.JsonOutput

process VISUALIZE_ANCESTRY {

  publishDir params.output, mode: 'copy'

  input:
    path(ancestry_estimation_report)
    path(population_files)
    path(reference_pc_coord)
    path(reference_samples)

  output:
    path ("estimated-populations.txt")
    path ("*.html")

  script:

    """
    
    # merge csv files
    csvtk concat ${population_files} > estimated-populations.txt

    # create PCA plot
    Rscript -e "require( 'rmarkdown' ); render('${ancestry_estimation_report}',
        params = list(
            populations = 'estimated-populations.txt',
            reference_pc_coord = '${reference_pc_coord}',
            reference_samples = '${reference_samples}'
        ),
        intermediates_dir='\$PWD',
        knit_root_dir='\$PWD',
        output_file='\$PWD/08-estimated-populations.html'
    )"

    """

}
