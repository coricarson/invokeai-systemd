#!/bin/bash
# Provide your own token here.
export HUGGING_FACE_HUB_TOKEN=hf_.......hunter2

#export CONTAINER_FLAVOR=cpu
export CONTAINER_FLAVOR=cuda
export GPU_FLAGS=all
export INVOKEAI_BRANCH="discarded/2.3.5.post2"

source ./docker/env.sh

# Only build if we need to.
docker inspect --type=image "${CONTAINER_IMAGE:-invokeai}" >/dev/null 2>&1 || ./docker/build.sh

# Ensure permissions, especially after a backup/restore.
docker run --rm --network=none -v invokeai_outputs:/outputs busybox:stable chown -R 1000:1000 /outputs
docker run --rm --network=none -v invokeai_data:/data busybox:stable chown -R 1000:1000 /data

./docker/run.sh --web --host 0.0.0.0 --port 9090 --outdir /outputs --no-nsfw_checker
