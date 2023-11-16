process CREATE_HTML_REPORT {

    publishDir params.output, mode: 'copy'

    input:
    path(merged_score)
    path(merged_info)
    path(scores_meta)
    path(estimated_ancestry)

    output:
    path "*.html", emit: html_report
    path "*.coverage.txt", emit: coverage_report

    script:
    samples = params.ancestry.enabled ? "--samples ${estimated_ancestry}" : ""

    """
    pgs-calc report \
        --data ${merged_score} \
        --info ${merged_info} \
        --meta ${scores_meta} \
        $samples \
        --out scores.html

    pgs-calc report \
        --data ${merged_score} \
        --info ${merged_info} \
        --meta ${scores_meta} \
        --template txt \
        --out scores.coverage.txt
    """

}