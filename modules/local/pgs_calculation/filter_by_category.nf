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
    """

}