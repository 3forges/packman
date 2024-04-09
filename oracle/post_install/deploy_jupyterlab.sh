#!/bin/bash

export DESIRED_VERSION=${DESIRED_VERSION:-"0.0.2"}
export GIT_REPO_URI='https://github.com/decoder-leco/poc-data-visualization.git'

export INSTALL_HOME=${HOME}/.jupyterlab

mkdir -p ${INSTALL_HOME}

git clone ${GIT_REPO_URI} ${INSTALL_HOME}

cd ${INSTALL_HOME}

git checkout ${DESIRED_VERSION}


docker-compose build jupyter_deno

docker-compose up -d jupyter_deno
