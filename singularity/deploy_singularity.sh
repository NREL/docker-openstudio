#!/usr/bin/env bash

docker build -f singularity/Dockerfile -t singularity .
# OPENSTUDIO_VERSION and OPENSTUDIO_SHA are set by travis
#export OPENSTUDIO_VERSION=2.6.0
#export OPENSTUDIO_SHA=ac20db5eff
docker build -t docker-openstudio --build-arg OPENSTUDIO_VERSION=$OPENSTUDIO_VERSION --build-arg OPENSTUDIO_SHA=$OPENSTUDIO_SHA .

# Start the registry and push docker-openstudio
docker run -d -p 5000:5000 --restart=always --name registry registry:2
docker tag docker-openstudio localhost:5000/docker-openstudio
docker push localhost:5000/docker-openstudio

# Launch the singularity container
docker run -it --rm --privileged --network=container:registry -v $(pwd):/root/build -v /var/run/docker.sock:/var/run/docker.sock singularity /root/build/singularity/build_singularity.sh


# Test with non-root user
# docker run -it --rm --privileged -u 1000 -v $(pwd):/root/build -v /var/run/docker.sock:/var/run/docker.sock singularity bash
# docker export for_export | singularity image.import docker-openstudio.simg
# singularity shell -B $(pwd):/singtest docker-openstudio.simg
# RUBYLIB isn't copied into Singularity container for some reason
#export RUBYLIB=/usr/local/openstudio-2.6.0/Ruby
#ruby /singtest/test/test.rb
ls -alR

# Determine the name of the tag
IMAGETAG=skip
if [ "${TRAVIS_BRANCH}" == "develop" ]; then
    IMAGETAG=develop
elif [ "${TRAVIS_BRANCH}" == "master" ]; then
    # Retrieve the version number from package.json
    IMAGETAG=$( docker run -it openstudio:latest ruby -r openstudio -e "puts OpenStudio.openStudioVersion" )
    OUT=$?
    if [ $OUT -eq 0 ]; then
        IMAGETAG=$( echo $IMAGETAG | tr -d '\r' )
        echo "Found OpenStudio Version: $IMAGETAG"
    else
        echo "ERROR Trying to find OpenStudio Version"
        IMAGETAG=skip
    fi
elif [ "${TRAVIS_BRANCH}" == "singularity" ]; then
    IMAGETAG=$( docker run -it openstudio:latest ruby -r openstudio -e "puts OpenStudio.openStudioVersion" )
fi

# upload to s3. The OPENSTUDIO_SHA is taken from the env vars
pip install -r singularity/requirements.txt
python singularity/upload_s3.py --version IMAGETAG
