#!/bin/sh
module load apptainer cuda

cat config/mock/mockdata_run.yaml | sed "s,/Users/claudy/work/projects/BioPathNet,$(pwd),g" > config/mock/mockdata_run_apptainer.yaml

cmd="srun \
    -p gpu \
    -q gpu \
    --gres=gmem:50G,gpu:1 \
    --mem=50G \
    apptainer \
        run \
            --nv \
            --writable-tmpfs \
            --cleanenv \
            --bind $HOME --bind $(pwd):/BioPathNet \
            biopathnet.sif -f run -c config/mock/mockdata_run_apptainer.yaml --gpus [0] $@"

echo "Submitting:" >&2
echo $cmd >&2
$cmd
