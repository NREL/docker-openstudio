#!/usr/bin/env bash

base_image_name=nrel/openstudio:base

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

    # Login to docker
    docker login -u $DOCKER_USER -p $DOCKER_PASS

    # If the base image doesn't already exists, build it
    if [ -z $(docker images -q $base_image_name) ]; then
      echo "Building $base_image_name (not found)"
      docker build -f Dockerfile-Base -t $base_image_name .
      # Not sure how travis works (can it store the local base image?)
      # Otherwise push it
      docker push $base_image_name
    else
      # Otherwise, Check whether the base image is older than a month
      base_image_created_date=$(docker inspect -f '{{ .Created }}' $base_image_name)
      date_sec_base_image=$(date -d $base_image_created_date +%s)
      date_sec_now=$(date +%s)
      older_than_one_month=$(( ($date_sec_now - $date_sec_base_image) > 60*24*30))

      if [ $older_than_one_month ]; then
        # If older than a month, ask whether the user wants to rebuild
        # For TRAVIS I guess you can just delete that and force rebuild
        echo "The base image $base_image_name is older than one month, rebuild? [Y/n]"
        read -n 1 -r
        echo    # (optional) move to a new line
        # Default is yes, so anything else than 'n' will trigger rebuild
        if [[ ! $REPLY =~ ^[Nn]$ ]]
        then
            echo -e "* Rebuilding the base image $base_image_name from Dockerfile-Base"
            docker rmi $base_image_name
            docker build -f Dockerfile-Base -t $base_image_name .
            # Push?
            docker push $base_image_name
        fi
      else
        echo "Found the base image $base_image_name which is newer than one month"
      fi
    fi

    docker build -f Dockerfile -t nrel/openstudio:$IMAGETAG -t nrel/openstudio:latest .
    docker push nrel/openstudio:$IMAGETAG
    docker push nrel/openstudio:latest
else
    echo "Not on a deployable branch, this is a pull request or has been explicity skipped"
fi
