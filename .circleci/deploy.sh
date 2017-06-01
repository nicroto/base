#!/bin/bash

set -e

## Required environment variables in your CircleCI dashboard
# (used to push to Docker Hub)
#
# $DOCKER_USER  - Docker Hub username
# $DOCKER_PASS  - Docker Hub password
# $DOCKER_EMAIL - Docker Hub email

# Master branch versioned deployment (only runs when a version number git tag exists - syntax: "v1.2.3")
if [[ "$CIRCLE_BRANCH" == "master" ]]; then
  # check if we're on a version tagged commit
  VERSION=$(git describe --tags | grep "^v[0-9]\+\.[0-9]\+\.[0-9]\+$")

  if [[ "$VERSION" ]]; then
    IMAGE_NAME=${DOCKER_IMAGE_NAME:-"reactioncommerce/base"}

    # create a versioned tags
    docker tag $IMAGE_NAME:devbuild $IMAGE_NAME:$VERSION-devbuild
    docker tag $IMAGE_NAME:latest $IMAGE_NAME:$VERSION

    # login to Docker Hub
    docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS

    # push the versioned builds
    docker push $IMAGE_NAME:$VERSION-devbuild
    docker push $IMAGE_NAME:$VERSION

    # push the latest
    docker push $IMAGE_NAME:devbuild
    docker push $IMAGE_NAME:latest
  else
    echo "On a deployment branch, but no version tag was found. Skipping image deployment."
  fi
else
  echo "Not in a deployment branch. Skipping image deployment."
fi