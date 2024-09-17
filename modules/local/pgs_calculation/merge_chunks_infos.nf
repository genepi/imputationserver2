process MERGE_CHUNKS_INFOS {
    
  label 'pgs'
  publishDir params.output, mode: 'copy'

  input:
  path(report_chunks)

  output:
  path "*.info", emit: merged_info_files

  script:
  def avail_mem = 1024
  if (!task.memory) {
      log.info '[MERGE_CHUNKS_INFOS] Available memory not known - defaulting to 1GB. Specify process memory requirements to change this.'
  } else {
      avail_mem = (task.memory.mega*0.8).intValue()
  }

  """
  java -Xmx${avail_mem}M -jar /opt/pgs-calc/pgs-calc.jar \
      merge-info ${report_chunks} \
      --out scores.info
  """

}