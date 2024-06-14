include { CALCULATE_CHUNKS } from '../modules/local/pgs_calculation/calculate_chunks'
include { MERGE_CHUNKS_INFOS } from '../modules/local/pgs_calculation/merge_chunks_infos'
include { MERGE_CHUNKS_SCORES } from '../modules/local/pgs_calculation/merge_chunks_scores'
include { CREATE_HTML_REPORT } from '../modules/local/pgs_calculation/create_html_report'
include { FILTER_BY_CATEGORY } from '../modules/local/pgs_calculation/filter_by_category'


workflow PGS_CALCULATION {
    
    take: 
    imputed_chunks
    estimated_ancestry
    

    main:    
    scores_txt = file(params.pgscatalog.scores, checkIfExists:true)
    scores_info = file(params.pgscatalog.scores + ".info", checkIfExists:true)
    scores_index = file(params.pgscatalog.scores + ".tbi", checkIfExists:true)
    scores_meta = file(params.pgscatalog.meta, checkIfExists:true)

    FILTER_BY_CATEGORY(
        scores_meta,
        params.pgs.category
    )

    CALCULATE_CHUNKS(
        imputed_chunks,
        tuple(scores_txt, scores_info, scores_index),
        FILTER_BY_CATEGORY.out.scores
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
        scores_meta,
        estimated_ancestry.collect().ifEmpty([])
    )

}