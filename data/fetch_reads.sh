#!/usr/bin/env bash

set -eu

nextflow run \
    'nf-core/fetchngs' \
    -params-file 'params.yml' \
    -profile docker \
    -resume
