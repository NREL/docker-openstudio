#!/usr/bin/env bash
IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
echo "image would be tagged as $IMAGETAG if this were master branch"
IMAGETAG=skip
if [ "${TRAVIS_BRANCH}" == "2.9.X-LTS" ]; then
    IMAGETAG=2.9.X-LTS
elif [ "${TRAVIS_BRANCH}" == "develop" ]; then
    IMAGETAG=develop
elif [ "${TRAVIS_BRANCH}" == "master" ]; then
    IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
fi

if [ "${IMAGETAG}" != "skip" ] && [ "${TRAVIS_PULL_REQUEST}" == "false" ]; then
    echo "Tagging image as $IMAGETAG"

    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
    docker tag openstudio:latest nrel/openstudio:$IMAGETAG; (( exit_status = exit_status || $? ))
    docker tag openstudio:latest nrel/openstudio:latest; (( exit_status = exit_status || $? ))
    docker push nrel/openstudio:$IMAGETAG; (( exit_status = exit_status || $? ))

    if [ "${TRAVIS_BRANCH}" == "master" ]; then
	# Deploy master as the latest.
        docker push nrel/openstudio:latest; (( exit_status = exit_status || $? ))
    fi

    exit $exit_status
else
    echo "Not on a deployable branch, this is a pull request or has been explicity skipped"
fi
