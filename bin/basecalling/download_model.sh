#!/bin/bash

VERSION=1.0.0

models_dir=~/dorado-${VERSION}-linux-x64/models

mkdir -p $models_dir

echo "Downloading model $model"
dorado download \
  --model $model \
  --models-directory $models_dir
