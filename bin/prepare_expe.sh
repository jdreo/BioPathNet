#!/bin/sh

set -e
set -o pipefail

if [ $# -ne 2 ] ; then
    echo "Usage: $(basename $0) <input_conf> <input_datadir>" >&2
    echo "This will use the current working directory for outputs." >&2
    exit 2
fi


module load apptainer cuda

input_conf="$1"
shift

# Need realpath for the underlying BPN run in a container that mounts the CWD.
input_datadir="$(realpath $1)"
shift

work_dir="$(pwd)"
expe_conf="config_$(date -Iseconds).yaml"

conf_dir="$(realpath $(dirname $input_conf))"
bpn_dir="${conf_dir%BioPathNet/*}BioPathNet/"
if [ ! -f ${bpn_dir}/pyproject.toml ] ; then
    echo "ERROR: the directory inferred from the config file path does not contains BioPathNet: '$bpn_dir'"
    exit 3
fi
if [ ! -f $bpn_dir/biopathnet.sif ] ; then
    echo "ERROR: I cannot find a 'biopathnet.sif' container in inferred BioPathNet directory: '${bpn_dir}'" >&2
    echo "Build it with 'bin/build_apptainer.sh' from your BioPathNet directory."
    exit 4
fi
# Link the container.
ln -s -f $bpn_dir/biopathnet.sif

# Instantiate the config file.
cat $input_conf | sed "s,{{DATA_DIR}},${input_datadir},g" | sed "s,{{OUTPUT_DIR}},${work_dir},g" > ${expe_conf}


echo "Config:" >&2
cat ${expe_conf}

