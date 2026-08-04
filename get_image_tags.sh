#!/usr/bin/env bash
# Determines the image tag to use based on the branch and manual-tag inputs.
# This file is sourced by deploy_docker.sh and merge_manifests.sh; it sets
# IMAGETAG (or "skip" when nothing should be deployed/merged) and DOCKER_REPO.
#
# Usage: source "$(dirname "$0")/get_image_tags.sh"
set -euo pipefail

IMAGETAG=skip
DOCKER_REPO=${DOCKER_REPO:-nrel/openstudio}

# Check branch name for correct tagging
if [ "${GITHUB_REF}" == "refs/heads/develop" ]; then
    IMAGETAG="develop"
elif [ "${GITHUB_REF}" == "refs/heads/2.9.X-LTS" ]; then
    IMAGETAG="2.9.X-LTS"
elif [ "${GITHUB_REF}" == "refs/heads/master" ]; then
    # Retrieve the version number from the workflow env
    IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
# Uncomment and set branch name for custom builds.
elif [ "${GITHUB_REF}" == "refs/heads/custom_branch_name" ]; then
    IMAGETAG="experimental"
elif [ "${DOCKER_MANUAL_IMAGE_TAG}" == "develop" ]; then
    IMAGETAG="develop"
fi

# Check if this is a manual installer GH action
if [ ! -z "${DOCKER_MANUAL_IMAGE_TAG:-}" ]; then
  if [ "${DOCKER_MANUAL_IMAGE_TAG}" == "develop" ]; then
    IMAGETAG="develop"
  elif [[ "${DOCKER_MANUAL_IMAGE_TAG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    IMAGETAG="${DOCKER_MANUAL_IMAGE_TAG}"
  else
    IMAGETAG="dev-${DOCKER_MANUAL_IMAGE_TAG}"
  fi
fi
