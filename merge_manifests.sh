#!/usr/bin/env bash
# Merges the arch-suffixed images pushed by deploy_docker.sh into canonical
# multi-arch manifests (e.g. nrel/openstudio:3.10.0-amd64 + -arm64 -> :3.10.0).
# Requires docker buildx (bundled with Docker CLI 19.03+).
#
# Required env: DOCKER_USER, DOCKER_PASS, OPENSTUDIO_VERSION, OPENSTUDIO_VERSION_EXT
# Optional env: DOCKER_MANUAL_IMAGE_TAG
set -euo pipefail

source "$(dirname "$0")/get_image_tags.sh"

if [ "${IMAGETAG}" == "skip" ] || [ -n "${GITHUB_BASE_REF:-}" ]; then
    echo "Nothing to merge — not on a deployable branch"
    exit 0
fi

echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

merge() {
    local canonical=$1
    echo "Creating multi-arch manifest ${DOCKER_REPO}:${canonical}"
    docker buildx imagetools create \
        -t "${DOCKER_REPO}:${canonical}" \
        "${DOCKER_REPO}:${canonical}-amd64" \
        "${DOCKER_REPO}:${canonical}-arm64"
}

merge "${IMAGETAG}"

if [ "${IMAGETAG}" == "develop" ]; then
    merge "develop"
fi

# Only update 'latest' if this is a stable release (no extension)
if [ -z "${OPENSTUDIO_VERSION_EXT}" ]; then
    echo "Stable release detected. Updating multi-arch 'latest'."
    merge "latest"
else
    echo "Pre-release detected (extension: '${OPENSTUDIO_VERSION_EXT}'). Skipping 'latest' manifest."
fi

echo "Done merging multi-arch manifests for ${IMAGETAG}"
