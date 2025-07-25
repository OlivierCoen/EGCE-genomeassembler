#!/usr/bin/env bash

REPO_NAME=herro
VERSION=0.0.2

echo "Login to quay.io"
docker login quay.io

echo "Building image"
docker build -t ${REPO_NAME} .

REMOTE_IMAGE="quay.io/ocoen/${REPO_NAME}:${VERSION}"
echo "Tagging to ${REMOTE_IMAGE}"
docker tag $REPO_NAME $REMOTE_IMAGE

echo "Pushing to ${REMOTE_IMAGE}"
docker push $REMOTE_IMAGE
