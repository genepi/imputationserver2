process CREATE_HTML_REPORT {
    
    label 'pgs'
    publishDir params.output, mode: 'copy'

    input:
    path(merged_score)
    path(merged_info)
    path(scores_meta)
    path(estimated_ancestry)

    output:
    path "scores.html", emit: html_report
    path "scores.report.zip", emit: zip_report
    path "scores.coverage", emit: coverage_report

    script:
    samples = (params.ancestry != null && params.ancestry != "" && params.ancestry.enabled) ? "--samples ${estimated_ancestry}" : ""
    def avail_mem = 1024
    if (!task.memory) {
        log.info '[CREATE_HTML_REPORT] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = (task.memory.mega*0.8).intValue()
    }

    """
    java -Xmx${avail_mem}M -jar /opt/pgs-calc/pgs-calc.jar \
        report \
        --info ${merged_info} \
        --meta ${scores_meta} \
        $samples \
        --out scores.html

    java -Xmx${avail_mem}M -jar /opt/pgs-calc/pgs-calc.jar \
        report \
        --data ${merged_score} \
        --info ${merged_info} \
        --meta ${scores_meta} \
        --template multi-page \
        $samples \
        --out scores.details.html

    7z a scores.report.zip scores.details.html scores
    rm -rf scores.details.html scores

    java -Xmx${avail_mem}M -jar /opt/pgs-calc/pgs-calc.jar \
        report \
        --data ${merged_score} \
        --info ${merged_info} \
        --meta ${scores_meta} \
        --template txt \
        --out scores.coverage
    """

}