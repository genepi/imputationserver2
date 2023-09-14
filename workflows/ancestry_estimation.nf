include { PREPARE_TRACE } from '../modules/local/ancestry_estimation/prepare_trace'
include { EXECUTE_TRACE } from '../modules/local/ancestry_estimation/execute_trace'
include { ESTIMATE_ANCESTRY } from '../modules/local/ancestry_estimation/estimate_ancestry'
include { VISUALIZE_ANCESTRY } from '../modules/local/ancestry_estimation/visualize_ancestry'

workflow ANCESTRY_ESTIMATION {
    
    Channel
        .fromPath(params.files)
        .set {files}

    Channel
        .fromPath(params.ancestry.references)
        .set {references}

    PREPARE_TRACE(
        files.collect(),
        references.first{it.getExtension()=='site'}
    )

    EXECUTE_TRACE(
        PREPARE_TRACE.out.batches.flatten(),
        PREPARE_TRACE.out.vcf.collect(),
        references.first{it.getExtension()=='site'},
        references.first{it.getExtension()=="range"},
        references.first{it.getExtension()=="geno"},
        references.first{it.getExtension()=="coord"},
        references.first{it.getExtension()=="samples"}
    )

    ESTIMATE_ANCESTRY(
        EXECUTE_TRACE.out.pcs.collect(),
        references.first{it.getExtension()=="coord"},
        references.first{it.getExtension()=="samples"}
    )

    VISUALIZE_ANCESTRY(
        file("${baseDir}/files/ancestry-estimation.Rmd"),
        ESTIMATE_ANCESTRY.out.populations.collect(),
        references.first{it.getExtension()=="coord"},
        references.first{it.getExtension()=="samples"}
    )
  
}