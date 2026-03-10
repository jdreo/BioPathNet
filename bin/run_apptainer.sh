#!/usr/bin/bash

set -e
set -o pipefail


usage() {
    echo "Usage: $0 <command> <config> <gpus> [seed]" >&2
    echo "Example: $0 run config/mock/mockdata_run.yaml [0] 1234" >&2
    echo "Available commands:" >&2
    for f in script/*.py ; do
        echo "    $(basename -s .py $f)"
    done
}

if [[ "$1" == "-h" || "$1" == "--help" ]] ; then
    usage
    exit 0
fi

if [[ $# -eq 3 ]] ; then
    CMD=$1
    CONFIG=$2
    GPUS=$3
    SEED=""
else
    if [[ $# -eq 4 ]] ; then
        CMD=$1
        CONFIG=$2
        GPUS=$3
        SEED=$4
    else
        usage
        exit 2
    fi
fi

cd $(dirname $0)
SCRIPT="../script/${CMD}.py"
CONF="../$CONFIG"

if [[ ! -f "$SCRIPT" ]] ; then
    echo "Unknown command: $CMD"
    usage
    exit 1
fi

if [[ ! -f "$CONF" ]] ; then
    echo "Unknown config file: $CONF"
    usage
    exit 1
fi

echo "Running BioPathNet..." >&2
echo "    script: ${CMD}.py" >&2
echo "    config: ${CONF}"   >&2
echo "    gpus: ${GPUS}"     >&2

if [[ $SEED -eq 0 || -z "$SEED" ]] ; then
    SEED_OPT=""
    echo "    seed: none" >&2
else
    SEED_OPT="-s $SEED"
    echo "    seed: ${SEED}" >&2
fi

cmd="/venv/bin/python $SCRIPT -c ${CONF} --gpus ${GPUS} $SEED_OPT"
echo "$cmd" >&2
$cmd

