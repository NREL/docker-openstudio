#!/usr/bin/env bash

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
fi

if [ "${IMAGETAG}" != "skip" ] && [ "${TRAVIS_PULL_REQUEST}" == "false" ]; then
    echo "Tagging image as $IMAGETAG"

    docker login -u $DOCKER_USER -p $DOCKER_PASS
    docker build -f Dockerfile -t nrel/openstudio:$IMAGETAG -t nrel/openstudio:latest .
    docker push nrel/openstudio:$IMAGETAG

    if [ "${TRAVIS_BRANCH}" == "master" ]; then
        # Deploy master as the latest.
        docker push nrel/openstudio:latest
    fi
else
    echo "Not on a deployable branch, this is a pull request or has been explicity skipped"
fi
