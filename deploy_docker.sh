#!/usr/bin/env bash
# Builds the locally-built image, tags it with an arch suffix, and pushes it.
# The canonical (multi-arch) tags are created later by merge_manifests.sh.
#
# Required env: DOCKER_USER, DOCKER_PASS, OPENSTUDIO_VERSION, OPENSTUDIO_VERSION_EXT
# Optional env: DEPLOY_ARCH (amd64|arm64, default amd64), DOCKER_MANUAL_IMAGE_TAG
set -euo pipefail

source "$(dirname "$0")/get_image_tags.sh"
DEPLOY_ARCH=${DEPLOY_ARCH:-amd64}

# GITHUB_BASE_REF is only set on Pull Request events. Do not build those
if [ "${IMAGETAG}" == "skip" ] || [ -n "${GITHUB_BASE_REF:-}" ]; then
    echo "Not on a deployable branch, this is a pull request or has been explicitly skipped"
    exit 0
fi

echo "Tagging image as ${IMAGETAG}-${DEPLOY_ARCH} and pushing to ${DOCKER_REPO}"

echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

# Push the arch-suffixed image. The canonical tag is assembled later by the
# manifest job so that parallel amd64/arm64 pushes never clobber each other.
ARCH_TAG="${DOCKER_REPO}:${IMAGETAG}-${DEPLOY_ARCH}"
docker tag openstudio:latest "${ARCH_TAG}"
docker push "${ARCH_TAG}"

# If on develop branch, also push the develop tag pointing to this image
if [ "${IMAGETAG}" == "develop" ]; then
    docker tag openstudio:latest "${DOCKER_REPO}:develop-${DEPLOY_ARCH}"
    docker push "${DOCKER_REPO}:develop-${DEPLOY_ARCH}"
fi

# Only update and push 'latest' if this is a stable release (no extension)
if [ -z "${OPENSTUDIO_VERSION_EXT}" ]; then
    echo "Stable release detected. Updating and pushing '${DOCKER_REPO}:latest-${DEPLOY_ARCH}'"
    docker tag openstudio:latest "${DOCKER_REPO}:latest-${DEPLOY_ARCH}"
    docker push "${DOCKER_REPO}:latest-${DEPLOY_ARCH}"
else
    echo "Pre-release detected (extension: '${OPENSTUDIO_VERSION_EXT}'). Skipping 'latest' tag update."
fi

echo "Done pushing ${DEPLOY_ARCH} artifacts for ${IMAGETAG}"
