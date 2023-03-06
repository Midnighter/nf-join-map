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

    def left = FASTQ_READCOUNT(ch_reads).counts
        .map { transform_counts(it) }  // tuple val(meta), val(count)
        .map { meta, count -> [meta.id, meta, count] }

    def right = ch_reads.map { meta, reads -> [meta.id, meta, reads] }

    left.collectFile(newLine: true, sort: true) { row ->
        ["left.tsv", "${row[0]}\t${System.identityHashCode(row[0])}"]
    }
    right.collectFile(newLine: true, sort: true) { row ->
        ["right.tsv", "${row[0]}\t${System.identityHashCode(row[0])}"]
    }

    // tuple val(meta), path(reads)
    def ch_counted_reads = left.join(right, failOnMismatch: true)  // tuple val(id), val(meta), val(count), val(meta), path(reads)
        .map { id, meta_left, count, meta_right, reads -> [meta_left, count, reads] }
        .map { add_counts_inplace(it) }

    FALCO(ch_counted_reads)

    def ch_mqc_input = FALCO.out.txt
        .map { meta, reports -> reports }
        .flatten()
        .filter { path -> path.name.endsWith('_data.txt')}
        .collect()

    MULTIQC(ch_mqc_input, [], multiqc_config, [])

}
