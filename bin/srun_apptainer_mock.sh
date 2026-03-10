#!/bin/sh
module load apptainer cuda

cat config/mock/mockdata_run.yaml | sed "s,/Users/claudy/work/projects/BioPathNet,$(pwd),g" > config/mock/mockdata_run_apptainer.yaml

srun \
    -p gpu \
    -q gpu \
    --gres=gmem:1G,gpu:1 \
    --mem=1G \
    apptainer \
        run \
            --nv \
            --writable-tmpfs \
            --cleanenv \
            --bind $HOME --bind $(pwd):/BioPathNet \
            biopathnet.sif script/run.py config/mock/mockdata_run_apptainer.yaml [0]

