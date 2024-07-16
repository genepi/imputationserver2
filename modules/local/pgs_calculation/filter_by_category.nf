process FILTER_BY_CATEGORY {

    input:
    path(meta)
    val(category)

    output:
    path "scores.txt", emit: scores

    script:
    """
    java -jar /opt/pgs-calc/pgs-calc.jar \
        filter \
        --meta ${meta} \
        --category '${category}' \
        --out scores.txt 

    # Count the number of lines in scores.txt
    line_count=\$(wc -l < scores.txt)

    echo "::group::"
    echo "Trait Category: ${category}"
    echo "Number of Scores: \${line_count}"
    echo "::endgroup::"

    """

}