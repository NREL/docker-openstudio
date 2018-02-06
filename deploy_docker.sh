#!/usr/bin/env bash

IMAGETAG=skip
if [ "${TRAVIS_BRANCH}" == "develop" ]; then
    IMAGETAG=develop
elif [ "${TRAVIS_BRANCH}" == "master" ]; then
    # Retrieve the version number from package.json
    IMAGETAG=$( docker run -it openstudio:latest ruby -r openstudio -e "puts OpenStudio.openStudioVersion" | tr '\n' '' )
    OUT=$?
    if [ $OUT -eq 0 ]; then
        echo "Found OpenStudio Version: $IMAGETAG"
    else
        echo "ERROR Trying to find OpenStudio Version"
        IMAGETAG=skip
    fi
fi

if [ "${IMAGETAG}" != "skip" ] && [ "${TRAVIS_PULL_REQUEST}" == "false" ]; then
    echo "Tagging image as $IMAGETAG"

    docker login -u $DOCKER_USER -p $DOCKER_PASS
    docker build -f Dockerfile -t nrel/openstudio:$IMAGETAG .
    docker tag nrel/openstudio nrel/openstudio:$IMAGETAG
    docker push nrel/openstudio:$IMAGETAG

    # also push to latest - since there really isn't a develop on this repo
    docker tag nrel/openstudio nrel/openstudio:latest
    docker push nrel/openstudio:latest
else
    echo "Not on a deployable branch, this is a pull request"
fi
