#!/usr/bin/bash

set -e
set -o pipefail

# Go to the repository
cd $(dirname $0)/..

if [[ ! -f "biopathnet.def" ]] ; then
    echo "ERROR: the given path does not point to a BioPathNet repository." >&2
    exit 2
fi

if command -v module ; then
    module load apptainer
fi
apptainer cache clean -f
apptainer build -F biopathnet.sif biopathnet.def


