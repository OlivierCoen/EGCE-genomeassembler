#!/usr/bin/env bash

REPO_NAME=pecat_medaka
PECAT_VERSION=0.0.3
MEDAKA_VERSION=v1.7.2

docker login quay.io

docker build -t ${REPO_NAME} .

docker tag ${REPO_NAME} quay.io/ocoen/${REPO_NAME}:${PECAT_VERSION}-${MEDAKA_VERSION}

docker push quay.io/ocoen/${REPO_NAME}:${PECAT_VERSION}-${MEDAKA_VERSION}
