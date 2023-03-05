#!/usr/bin/env bash

set -eu

nextflow run \
    'solution_copy.nf' \
    -profile docker \
    -resume
