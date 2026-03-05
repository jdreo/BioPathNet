#!/usr/bin/bash
# To be launched from the root of the BioPathNet directory.

set -e
set -o pipefail

#if command -v module ; then
#    module load apptainer
#fi


if [[ $# -eq 4 ]] ; then
    CMD=$1
    CONFIG=$2
    GPUS=$3
    SEED=""
else
    if [[ $# -eq 5 ]] ; then
        CMD=$1
        CONFIG=$2
        GPUS=$3
        SEED=$4
    else
        echo "Usage: $0 <command> <config> <gpus> [seed]" >&2
        echo "Example: $0 run config/mock/mockdata_run.yaml [0] 1234" >&2
        echo "Available commands:" >&2
        for f in script/*.py ; do
            echo "    $(basename -s .py $f)"
        done
        exit 2
    fi
fi

cd $(dirname $0)
SCRIPT="../script/${CMD}.py"
CONF="../$CONFIG"

echo "script: ${CMD}.py" >&2
echo "config: ${CONF}" >&2
echo "gpus: ${GPUS}"    >&2

if [[ $SEED -ne 0 || -z "$SEED" ]] ; then
    SEED_OPT="-s $SEED"
    echo "seed: ${SEED}" >&2
else
    SEED_OPT=""
    echo "seed: none" >&2
fi

/venv/bin/python $SCRIPT -c ${CONF} --gpus ${GPUS} $SEED_OPT

