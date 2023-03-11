#!/bin/bash
# Provide your own token here.
export HUGGING_FACE_HUB_TOKEN=hf_.......hunter2

export CONTAINER_FLAVOR=cpu
#export CONTAINER_FLAVOR=cuda
#export GPU_FLAGS=all

./docker/build.sh
./docker/run.sh --web --host 0.0.0.0 --port 9090 --outdir /outputs --no-nsfw_checker