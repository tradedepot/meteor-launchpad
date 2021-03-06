#!/bin/bash

## Required environment variables in your CircleCI dashboard
# (used to push to Docker Hub)
#
# $DOCKER_USERNAME  - Docker Hub username for docke
# $DOCKER_PASS  - Docker Hub password
# $DOCKER_EMAIL - Docker Hub email

## Optional environment variables
#
# $DOCKER_IMAGE_NAME - use to push the build to your own Docker Hub account (Default: tradedepot/meteor-launchpad)

# Master branch versioned deployment (only runs when a version number git tag exists - syntax: "v1.2.3")
if [[ "$CIRCLE_BRANCH" == "master" ]]; then
  # check if we're on a version tagged commit
  # VERSION=$(git describe --tags | grep "^v[0-9]\+\.[0-9]\+\.[0-9]\+$")

  if [ ! $CI ]; then
  	VERSION="localbuild"
  else
  	VERSION="$CIRCLE_BRANCH-$CIRCLE_BUILD_NUM"
  fi

  if [[ "$VERSION" ]]; then
    set -e

    IMAGE_NAME=${DOCKER_IMAGE_NAME:-"tradedepot/meteor-launchpad"}

    # create a versioned tags
    docker tag $IMAGE_NAME:devbuild $IMAGE_NAME:$VERSION-devbuild
    docker tag $IMAGE_NAME:latest $IMAGE_NAME:$VERSION

    # login to Docker Hub
    docker login -u $DOCKER_USERNAME -p $DOCKER_PASS

    # push the builds
    docker push $IMAGE_NAME:$VERSION-devbuild

    docker login -u $DOCKER_USERNAME -p $DOCKER_PASS
    docker push $IMAGE_NAME:devbuild

    docker login -u $DOCKER_USERNAME -p $DOCKER_PASS
    docker push $IMAGE_NAME:$VERSION

    docker login -u $DOCKER_USERNAME -p $DOCKER_PASS
    docker push $IMAGE_NAME:latest
  else
    echo "On a deployment branch, but no version tag was found. Skipping image deployment."
  fi
else
  echo "Not in a deployment branch. Skipping image deployment."
fi
