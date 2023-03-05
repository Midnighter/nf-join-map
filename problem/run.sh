#!/usr/bin/env bash

set -eu

nextflow run \
    'problem.nf' \
    -profile docker \
    -resume
