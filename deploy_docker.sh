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
  elif [[ "${DOCKER_MANUAL_IMAGE_TAG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    IMAGETAG="${DOCKER_MANUAL_IMAGE_TAG}"
  else
    IMAGETAG="dev-${DOCKER_MANUAL_IMAGE_TAG}"
  fi
fi

# GITHUB_BASE_REF is only set on Pull Request events. Do not build those
if [ "${IMAGETAG}" != "skip" ] && [[ -z "${GITHUB_BASE_REF}" ]]; then
    echo "Building and pushing multi-arch image as $IMAGETAG to ${DOCKER_REPO}"

    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

    # Build tags list
    TAGS="--tag ${DOCKER_REPO}:${IMAGETAG}"

    # Only update and push 'latest' if this is a stable release (no extension)
    if [ -z "${OPENSTUDIO_VERSION_EXT}" ]; then
        echo "Stable release detected. Will also push '${DOCKER_REPO}:latest'"
        TAGS="${TAGS} --tag ${DOCKER_REPO}:latest"
    else
        echo "Pre-release detected (extension: '${OPENSTUDIO_VERSION_EXT}'). Skipping 'latest' tag."
    fi

    # If on develop branch, also add the develop tag
    if [ "${IMAGETAG}" == "develop" ] || [ "${GITHUB_REF}" == "refs/heads/develop" ]; then
        TAGS="${TAGS} --tag ${DOCKER_REPO}:develop"
    fi

    # Build and push multi-arch image in one step (required for multi-platform manifests)
    docker buildx build \
        --platform=linux/amd64,linux/arm64 \
        --build-arg OPENSTUDIO_VERSION=${OPENSTUDIO_VERSION} \
        --build-arg OPENSTUDIO_SHA=${OPENSTUDIO_SHA} \
        --build-arg OPENSTUDIO_VERSION_EXT=${OPENSTUDIO_VERSION_EXT} \
        ${TAGS} \
        --push \
        .
    exit_status=$?

    exit $exit_status
else
    echo "Not on a deployable branch, this is a pull request or has been explicity skipped"
fi
