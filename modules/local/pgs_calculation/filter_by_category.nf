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

    # Create the JSON content
    json_content="[{\\"command\\":\\"MESSAGE\\",\\"params\\":[\\"Trait Category: ${category}<br>Number of Scores: \${line_count}\\", 0]}]"

    # Write the JSON content to a file
    echo \$json_content > cloudgene.report.json

    """

}