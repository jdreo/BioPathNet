#!/bin/sh
module load ninja cuda
srun -p gpu -q gpu --gres=gpu:1 apptainer run -B /pasteur/appa/homes/claudy --bind $(pwd):/BioPathNet biopathnet.sif script/run.py config/mock/mockdata_run.yaml [0]
