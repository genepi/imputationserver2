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
    def avail_mem = 1024
    if (!task.memory) {
        log.info '[CREATE_HTML_REPORT] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    java -Xmx${avail_mem}M -jar /opt/pgs-calc/pgs-calc.jar \
        report \
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