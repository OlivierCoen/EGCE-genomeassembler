#!/usr/bin/env bash

REPO_NAME=pecat
PECAT_VERSION=0.0.3

docker login quay.io

docker build -t ${REPO_NAME} .

docker tag ${REPO_NAME} quay.io/ocoen/${REPO_NAME}:${PECAT_VERSION}

docker push quay.io/ocoen/${REPO_NAME}:${PECAT_VERSION}
