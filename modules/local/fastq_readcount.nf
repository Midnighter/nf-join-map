process FASTQ_READCOUNT {
    tag "${meta.id}"
    label 'process_single'

    conda 'bioconda::seqtk=1.3'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqtk:1.3--h7132678_4' :
        'quay.io/biocontainers/seqtk:1.3--h7132678_4' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), stdout, emit: counts

    when:
    task.ext.when == null || task.ext.when

    script:
    def fastq = meta.single_end ? reads : reads[0]
    """
    seqtk seq '${fastq}' | paste - - - - | wc -l
    """
}
