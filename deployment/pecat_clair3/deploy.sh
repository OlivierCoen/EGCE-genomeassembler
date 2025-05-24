#!/usr/bin/env bash

REPO_NAME=pecat_clair3
PECAT_VERSION=0.0.3
CLAIR3_VERSION=v1.1.1

docker login quay.io

docker build -t ${REPO_NAME} .

docker tag ${REPO_NAME} quay.io/ocoen/${REPO_NAME}:${PECAT_VERSION}-${CLAIR3_VERSION}

docker push quay.io/ocoen/${REPO_NAME}:${PECAT_VERSION}-${CLAIR3_VERSION}
