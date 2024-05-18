#!/bin/bash

# export DESIRED_VERSION=${DESIRED_VERSION:-"0.0.2"}
export DESIRED_VERSION=${DESIRED_VERSION:-"feature/aarch64/version"}

export GIT_REPO_URI='https://github.com/decoder-leco/poc-data-visualization.git'

export INSTALL_HOME=${HOME}/.jupyterhub_build

mkdir -p ${INSTALL_HOME}

git clone ${GIT_REPO_URI} ${INSTALL_HOME}

cd ${INSTALL_HOME}

git checkout ${DESIRED_VERSION}


docker-compose build jupyterhub_deno_aarch64

# okay now there a new image :
# [decoderleco/r-deno-py-jupyter:0.0.1-alpha-aarch64-hub]

# docker-compose up -d jupyterhub_deno_aarch64
