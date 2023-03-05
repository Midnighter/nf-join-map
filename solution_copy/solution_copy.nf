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
        .splitCsv(header: true, sep: ',', quote: '"')
        .map { row ->
            [
                row + [id: row.run_accession, single_end: true],
                file("../data/${row.fastq_1}", checkIfExists: true)
            ]
        }

    def left = FASTQ_READCOUNT(ch_reads).counts
        .map { transform_counts(it) }  // tuple val(meta), val(count)

    def right = ch_reads

    left.collectFile(newLine: true, sort: true) { row ->
        ["left.tsv", "${row[0]['id']}\t${row[0]}\t${System.identityHashCode(row[0])}"]
    }
    right.collectFile(newLine: true, sort: true) { row ->
        ["right.tsv", "${row[0]['id']}\t${row[0]}\t${System.identityHashCode(row[0])}"]
    }

    // tuple val(meta), path(reads)
    def ch_counted_reads = left.join(right, failOnMismatch: true)
        .map { add_counts_copy(it) }

    FALCO(ch_counted_reads)

    // MULTIQC(FALCO.out.txt.collect { meta, data -> data }, [], [], [])
}
