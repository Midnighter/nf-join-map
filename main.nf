#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/******************************************************************************
 * Nf-core modules
 *****************************************************************************/

include { FALCO } from './modules/nf-core/falco/main'
include { MULTIQC } from '../modules/nf-core/multiqc/main'

/******************************************************************************
 * Local modules
 *****************************************************************************/

include { FASTQ_READCOUNT } from './modules/fastq_readcount'

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

def add_counts_copy(row) {
    def (meta, count, reads) = row
    return [meta + [total_reads: count], reads]
}

/******************************************************************************
 * Main workflow
 *****************************************************************************/

workflow {
    log.info """
************************************************************

FASTQ Read Count
================

Sample Sheet: ${params.input}
Results Path: ${params.outdir}

************************************************************

"""

    // tuple val(meta), path(reads)
    def ch_reads = Channel.fromPath(params.input, checkIfExists: true)
      .splitCsv(header: true, sep: '\t')
      .map { row -> [row + [id: row.sample], [file(row.fastq, checkIfExists: true)]] }

    ch_reads.view(meta, reads -> "${meta} <${System.identityHashCode(meta)}>")

    // tuple val(meta), path(reads)
    def ch_counted_reads = FASTQ_READCOUNT(ch_reads).counts
        .map { transform_counts(it) }  // tuple val(meta), val(count)
        .join(ch_reads)  // tuple val(meta), val(count), path(reads)
        .map { add_counts_inplace(it) }

    ch_counted_reads.view(meta, reads -> "${meta} <${System.identityHashCode(meta)}>")

    FALCO(ch_counted_reads)

    MULTIQC(FALCO.out.txt.collect())

}
