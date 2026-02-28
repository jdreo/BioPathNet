#!/usr/bin/bash
# To be launched from the root of the BioPathNet directory.


set -e
set -o pipefail

#if command -v module ; then
#    module load apptainer
#fi

echo $(dirname $0)
cd $(dirname $0)

SCRIPT=$1
CONFIG=$2
GPUS=$3

echo "script=${SCRIPT}"
echo "config=${CONFIG}"
echo "gpus=${GPUS}"

echo "nb args=$#"

echo pwd
pwd

echo ls -la
ls -la

if [[ $1 == "script/run.py" ]] ; then
	echo "Launch run.py script"
	if [[ $# -eq 3 ]] ; then
		echo "No fixed seed"
		../${SCRIPT} -c ../${CONFIG} --gpus ${GPUS}
	else
		if [[ $# -eq 4 ]] ; then
			echo "Fixed seed=${SEED}"
			SEED=$4
			$SCRIPT -s $SEED -c $CONFIG --gpus $GPUS
		fi
	fi
fi

#apptainer run -B /pasteur/appa/homes/claudy --bind $(pwd):/BioPathNet biopathnet.sif script/run.py config/mock/mockdata_run.yaml [0]
