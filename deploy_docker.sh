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

    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
    docker tag openstudio:latest nrel/openstudio:$IMAGETAG; (( exit_status = exit_status || $? ))
    docker tag openstudio:latest nrel/openstudio:latest; (( exit_status = exit_status || $? ))
    docker tag openstudio-cli:latest nrel/openstudio-cli:$IMAGETAG; (( exit_status = exit_status || $? ))
    docker tag openstudio-cli:latest nrel/openstudio-cli:latest; (( exit_status = exit_status || $? ))
    docker push nrel/openstudio:$IMAGETAG; (( exit_status = exit_status || $? ))
    docker push nrel/openstudio-cli:$IMAGETAG; (( exit_status = exit_status || $? ))

    if [ "${TRAVIS_BRANCH}" == "master" ]; then
	# Deploy master as the latest.
        docker push nrel/openstudio:latest; (( exit_status = exit_status || $? ))
        docker push nrel/openstudio-cli:latest (( exit_status = exit_status || $? ))
    fi

    exit $exit_status
else
    echo "Not on a deployable branch, this is a pull request or has been explicity skipped"
fi

# Deploy the singularity image