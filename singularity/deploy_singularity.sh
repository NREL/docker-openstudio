#!/usr/bin/env bash

# Building a container with singularity installed to build the OpenStudio singularity image
docker build -f singularity/Dockerfile -t singularity .
# OPENSTUDIO_VERSION and OPENSTUDIO_SHA are set by travis
# export OPENSTUDIO_VERSION=2.6.0
# export OPENSTUDIO_SHA=ac20db5eff
docker build -t docker-openstudio --target base --build-arg OPENSTUDIO_VERSION=$OPENSTUDIO_VERSION --build-arg OPENSTUDIO_SHA=$OPENSTUDIO_SHA --build-arg OPENSTUDIO_VERSION_EXT=$OPENSTUDIO_VERSION_EXT .

# Start the registry and push docker-openstudio
docker run -d -p 5000:5000 --restart=always --name registry registry:2
sleep 5
docker tag docker-openstudio localhost:5000/docker-openstudio
docker push localhost:5000/docker-openstudio

docker ps

# Launch the singularity container
docker run --rm --privileged --network=container:registry -v $(pwd):/root/build -v /var/run/docker.sock:/var/run/docker.sock singularity /root/build/singularity/build_singularity.sh

# Shut down and remove the local registry
docker container stop registry && docker container rm -v registry

ls -altR

# Test with non-root user. The -u 1000 is not needed when testing locally on OSX.
# docker run -it --rm --privileged -u 1000 -v $(pwd):/root/build -v /var/run/docker.sock:/var/run/docker.sock singularity bash
# singularity shell -B $(pwd):/singtest docker-openstudio.simg
#ruby /singtest/test/test.rb
#ls -alR

# Determine the name of the tag
IMAGETAG=skip
if [ "${GITHUB_REF}" == "refs/heads/develop" ]; then
    IMAGETAG=develop
elif [ "${GITHUB_REF}" == "refs/heads/2.9.X-LTS" ]; then
    IMAGETAG="2.9.X-LTS"
elif [ "${GITHUB_REF}" == "refs/heads/master" ]; then
    IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
 # Uncomment and set branch name for custom builds.
elif [ "${GITHUB_REF}" == "refs/heads/HVACFlexMeasures-2-1" ]; then
    IMAGETAG=flex-2
fi

# upload to s3. The OPENSTUDIO_SHA is taken from the env vars
if [ "$IMAGETAG" != "skip" ]; then
    pip install -r singularity/requirements.txt
    python singularity/upload_s3.py
fi

