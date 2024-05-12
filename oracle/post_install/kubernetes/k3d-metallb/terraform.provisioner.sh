#!/bin/bash

if [ -d ./packman ]; then
  rm -fr ./packman
fi;

# 0 - git clone the thing
export PACKMAN_DESIRED_VERSION="feature/packer/full/appliances/lifecycle"
git clone https://github.com/3forges/packman.git
cd ./packman
git checkout ${PACKMAN_DESIRED_VERSION}

cd ./oracle/post_install/kubernetes/k3d-metallb/

chmod +x ./*.sh
chmod +x ./*.k3d.sh

./provision.sh
# ./provision.k3d.sh

./troubleshoot.sh
# ./troubleshoot.k3d.sh
