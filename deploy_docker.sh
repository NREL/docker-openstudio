#!/usr/bin/env bash

builder_image_name=nrel/openstudio:builder

IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
echo "image would be tagged as $IMAGETAG if this were master branch"
IMAGETAG=skip
if [ "${TRAVIS_BRANCH}" == "develop" ]; then
    IMAGETAG=2.9.X-LTS
elif [ "${TRAVIS_BRANCH}" == "develop3" ]; then
    IMAGETAG=develop
elif [ "${TRAVIS_BRANCH}" == "master" ]; then
    IMAGETAG=${OPENSTUDIO_VERSION}${OPENSTUDIO_VERSION_EXT}
fi

if [ "${IMAGETAG}" != "skip" ] && [ "${TRAVIS_PULL_REQUEST}" == "false" ]; then
    echo "Tagging image as $IMAGETAG"

    # Login to docker
    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

    # If the base image doesn't already exists (it should, since it's used as the starting point for the base one we should built)
    # we build it
    if [ -z $(docker images -q $builder_image_name) ]; then
      echo "Building $builder_image_name (not found)"
      docker build --target builder -t nrel/openstudio:builder .
      # Not sure how travis works (can it store the local base image?)
      # Otherwise push it
      docker push $builder_image_name
    else
      # Otherwise, Check whether the base image is older than a month
      builder_image_created_date=$(docker inspect -f '{{ .Created }}' $builder_image_name)
      date_sec_builder_image=$(date -d $builder_image_created_date +%s)
      date_sec_now=$(date +%s)
      older_than_one_month=$(( ($date_sec_now - $date_sec_builder_image) > 60*24*30))

      if [ $older_than_one_month ]; then
        # If older than a month, ask whether the user wants to rebuild
        # For TRAVIS I guess you can just delete that and force rebuild
        echo "The builder image $builder_image_name is older than one month, rebuild? [Y/n]"
        read -n 1 -r
        echo    # (optional) move to a new line
        # Default is yes, so anything else than 'n' will trigger rebuild
        if [[ ! $REPLY =~ ^[Nn]$ ]]
        then
            echo -e "* Rebuilding the base image $builder_image_name from Dockerfile-Base"
            docker rmi $builder_image_name
            docker build -f Dockerfile-Base -t $builder_image_name .
            # Push?
            docker push $builder_image_name
        fi
      else
        echo "Found the base image $builder_image_name which is newer than one month"
      fi
    fi


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
