#!/bin/sh
module load apptainer ninja cuda gcc
srun -p gpu -q gpu --gres=gpu:1 apptainer run --nv --bind $HOME --bind $(pwd):/BioPathNet --bind /opt/gensoft:/opt/gensoft:ro biopathnet.sif script/run.py config/mock/mockdata_run.yaml [0]
