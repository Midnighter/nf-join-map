#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/******************************************************************************
 * Nf-core modules
 *****************************************************************************/

include { FALCO } from '../modules/nf-core/falco/main'
include { MULTIQC } from '../modules/nf-core/multiqc/main'

/******************************************************************************
 * Local modules
 *****************************************************************************/

include { FASTQ_READCOUNT } from '../modules/local/fastq_readcount'

/******************************************************************************
 * Helper functions
 *****************************************************************************/

def transform_counts(row) {
    def (meta, count) = row
    return [meta, count.strip().toInteger()]
}

def add_counts_inplace(row) {
    def (meta, count, reads) = row
    meta.total_reads = count
    return [meta, reads]
}

/******************************************************************************
 * Main workflow
 *****************************************************************************/

workflow {
    log.info """
************************************************************

FASTQ Read Count
================

Sample Sheet:   ${params.input}
MultiQC Config: ${params.multiqc_config}
Results Path:   ${params.outdir}

************************************************************

"""

    // tuple val(meta), path(reads)
    def ch_reads = Channel.fromPath(params.input, checkIfExists: true)
        .splitCsv(header: true, sep: ',', quote: '"')
        .map { row ->
            [
                row + [id: row.run_accession, single_end: true],
                file("../data/${row.fastq_1}", checkIfExists: true)
            ]
        }

    def multiqc_config = Channel.fromPath(params.multiqc_config, checkIfExists: true)
        .first()

    // tuple val(meta), path(reads)
    def ch_counted_reads = FASTQ_READCOUNT(ch_reads).counts
        .map { transform_counts(it) }
        .join(ch_reads, failOnMismatch: true)
        .map { add_counts_inplace(it) }

    FALCO(ch_counted_reads)

    def ch_mqc_input = FALCO.out.txt
        .map { meta, reports -> reports }
        .flatten()
        .filter { path -> path.name.endsWith('_data.txt')}
        .collect()

    MULTIQC(ch_mqc_input, [], multiqc_config, [])

}
