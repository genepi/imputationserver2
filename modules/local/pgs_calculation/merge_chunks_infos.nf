process MERGE_CHUNKS_INFOS {

  publishDir params.output, mode: 'copy'

  input:
  path(report_chunks)

  output:
  path "*.info", emit: merged_info_files

  """
  pgs-calc merge-info ${report_chunks} \
    --out ${params.project}.info
  """

}