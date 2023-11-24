process MERGE_CHUNKS_SCORES {

  publishDir params.output, mode: 'copy'

  input:
  path(score_chunks)

  output:
  path "*.txt", emit: merged_score_files

  script:
  def avail_mem = 1024
  if (!task.memory) {
      log.info '[MERGE_CHUNKS_SCORES] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
  } else {
      avail_mem = (task.memory.mega*0.8).intValue()
  }

  """
  java -Xmx${avail_mem}M -jar /opt/pgs-calc/pgs-calc.jar \
      merge-score ${score_chunks} \
      --out ${params.project}.scores.txt
  """

}