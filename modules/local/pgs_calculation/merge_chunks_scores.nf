process MERGE_CHUNKS_SCORES {

  publishDir params.output, mode: 'copy'

  input:
  path(score_chunks)

  output:
  path "*.txt", emit: merged_score_files

  """
  pgs-calc merge-score ${score_chunks} \
    --out ${params.project}.scores.txt
  """

}