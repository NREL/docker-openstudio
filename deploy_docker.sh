#!/usr/bin/env bash
IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
echo "default image tag would be $IMAGETAG"
IMAGETAG=skip
DOCKER_REPO=${DOCKER_REPO:-nrel/openstudio}

# Check branch name for correct tagging
if [ "${GITHUB_REF}" == "refs/heads/develop" ]; then
    IMAGETAG="develop"
elif [ "${GITHUB_REF}" == "refs/heads/2.9.X-LTS" ]; then
    IMAGETAG="2.9.X-LTS"
elif [ "${GITHUB_REF}" == "refs/heads/master" ]; then
    # Retrieve the version number from rails
    IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
# Uncomment and set branch name for custom builds.
elif [ "${GITHUB_REF}" == "refs/heads/custom_branch_name" ]; then
    IMAGETAG="experimental"
elif [ "${DOCKER_MANUAL_IMAGE_TAG}" == "develop" ]; then
    IMAGETAG="develop"
fi

# Check if this is a manual installer GH action
if [ ! -z "${DOCKER_MANUAL_IMAGE_TAG}" ]; then
  if [ "${DOCKER_MANUAL_IMAGE_TAG}" == "develop" ]; then
    IMAGETAG="develop"
  else
    IMAGETAG="dev-${DOCKER_MANUAL_IMAGE_TAG}"
  fi
fi

# GITHUB_BASE_REF is only set on Pull Request events. Do not build those
if [ "${IMAGETAG}" != "skip" ] && [[ -z "${GITHUB_BASE_REF}" ]]; then
    echo "Tagging image as $IMAGETAG and pushing to ${DOCKER_REPO}"

    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
    # Tag versioned image
    docker tag openstudio:latest ${DOCKER_REPO}:$IMAGETAG; (( exit_status = exit_status || $? ))

    # Only update and push 'latest' if this is a stable release (no extension)
    if [ -z "${OPENSTUDIO_VERSION_EXT}" ]; then
        echo "Stable release detected. Updating and pushing '${DOCKER_REPO}:latest'"
        docker tag openstudio:latest ${DOCKER_REPO}:latest; (( exit_status = exit_status || $? ))
        docker push ${DOCKER_REPO}:latest; (( exit_status = exit_status || $? ))
    else
        echo "Pre-release detected (extension: '${OPENSTUDIO_VERSION_EXT}'). Skipping 'latest' tag update."
    fi

    # Push versioned tag
    docker push ${DOCKER_REPO}:$IMAGETAG; (( exit_status = exit_status || $? ))
    # If on develop branch, also push the develop tag pointing to this image
    if [ "${IMAGETAG}" == "develop" ] || [ "${GITHUB_REF}" == "refs/heads/develop" ]; then
        docker tag openstudio:latest ${DOCKER_REPO}:develop; (( exit_status = exit_status || $? ))
        docker push ${DOCKER_REPO}:develop; (( exit_status = exit_status || $? ))
    fi

    exit $exit_status
else
    echo "Not on a deployable branch, this is a pull request or has been explicity skipped"
fi
