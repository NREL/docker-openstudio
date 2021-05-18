#!/usr/bin/env bash
IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
echo "image would be tagged as $IMAGETAG if this were master branch"
IMAGETAG=skip

if [ "${GITHUB_REF}" == "refs/heads/develop" ]; then
    IMAGETAG="develop"
elif [ "${GITHUB_REF}" == "refs/heads/2.9.X-LTS" ]; then
    IMAGETAG="2.9.X-LTS"
elif [ "${GITHUB_REF}" == "refs/heads/master" ]; then
    # Retrieve the version number from rails
    IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
# Uncomment and set branch name for custom builds.
elif [ "${GITHUB_REF}" == "refs/heads/custom_branch_name" ]; then
    IMAGETAG=experimental
fi

# GITHUB_BASE_REF is only set on Pull Request events. Do not build those
if [ "${IMAGETAG}" != "skip" ] && [[ -z "${GITHUB_BASE_REF}" ]]; then
    echo "Tagging image as $IMAGETAG"

    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
    docker tag openstudio:latest nrel/openstudio:$IMAGETAG; (( exit_status = exit_status || $? ))
    docker tag openstudio:latest nrel/openstudio:latest; (( exit_status = exit_status || $? ))
    docker push nrel/openstudio:$IMAGETAG; (( exit_status = exit_status || $? ))

    if [ "${GITHUB_REF}" == "refs/heads/master" ]; then
	# Deploy master as the latest.
        docker push nrel/openstudio:latest; (( exit_status = exit_status || $? ))
    fi

    exit $exit_status
else
    echo "Not on a deployable branch, this is a pull request or has been explicity skipped"
fi
