#!/bin/bash

# 0 - git clone the thing
export PACKMAN_DESIRED_VERSION="feature/packer/full/appliances/lifecycle"
git clone https://github.com/3forges/packman.git
cd ./packman
git checkout ${PACKMAN_DESIRED_VERSION}

cd ./oracle/post_install/kubernetes/k3d-metallb/

chmod +x *.sh

./provision.sh

./troubleshoot.sh
