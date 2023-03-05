#!/usr/bin/env bash

set -eu

nextflow run \
    'solution_keys.nf' \
    -profile docker \
    -resume
