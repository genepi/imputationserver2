include { CALCULATE_CHUNKS } from '../modules/local/pgs_calculation/calculate_chunks'
include { MERGE_CHUNKS_INFOS } from '../modules/local/pgs_calculation/merge_chunks_infos'
include { MERGE_CHUNKS_SCORES } from '../modules/local/pgs_calculation/merge_chunks_scores'
include { CREATE_HTML_REPORT } from '../modules/local/pgs_calculation/create_html_report'

workflow PGS_CALCULATION {
    
    take: 
    imputed_chunks
    estimated_ancestry
    

    main:    
    scores = Channel.fromPath(params.pgscatalog.scores, checkIfExists:true).collect()

    CALCULATE_CHUNKS(
        imputed_chunks,
        scores
    )

    MERGE_CHUNKS_SCORES(
        CALCULATE_CHUNKS.out.scores_chunks.collect()
    )
  
    MERGE_CHUNKS_INFOS(
        CALCULATE_CHUNKS.out.info_chunks.collect()
    )

    CREATE_HTML_REPORT(
        MERGE_CHUNKS_SCORES.out.collect(),
        MERGE_CHUNKS_INFOS.out.collect(),
        file(params.pgscatalog.meta, checkIfExists:true)
    )

}