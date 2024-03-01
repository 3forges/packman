#!/bin/bash

export PACKMAN_SSH_KEY_COMMENT=${PACKMAN_SSH_KEY_COMMENT:-""}
export PACKMAN_SSH_KEY_NEW_PASSPHRASE=${PACKMAN_SSH_KEY_NEW_PASSPHRASE:-""}
export PACKMAN_SSH_KEY_OLP_PASSPHRASE=${PACKMAN_SSH_KEY_OLD_PASSPHRASE:-""}

mkdir -p ./.ssh.packman/

if [ -f ./.ssh.packman/id_rsa ]; then
  rm -f ./.ssh.packman/id_rsa*
fi;

ssh-keygen -t rsa -b 4096 -f ./.ssh.packman/id_rsa -C "" -N "${PACKMAN_SSH_KEY_NEW_PASSPHRASE}" -P "${PACKMAN_SSH_KEY_OLP_PASSPHRASE}"
sleep 4s
chmod 700 -R ./.ssh.packman/
chmod 644 ./.ssh.packman/id_rsa
chmod 644 ./.ssh.packman/id_rsa.pub

if [ -d ./.shell/.build/ ]; then
  rm -fr ./.shell/.build/
  mkdir -p ./.shell/.build/
fi;

export VAGRANT_LX_USER_SSH_PUBKEY=$(cat ./.ssh.packman/id_rsa.pub)
export VAGRANT_LX_USER_NAME="vagrant"

cat <<EOF >./.shell/.build/setup.sh
export LX_USERNAME=${VAGRANT_LX_USER_NAME}
mkdir -p /home/\${LX_USERNAME}/.ssh/
chmod 700 -R /home/\${LX_USERNAME}/.ssh/
cat '$VAGRANT_LX_USER_SSH_PUBKEY' | tee -a /home/\${LX_USERNAME}/.ssh/authorized_keys
chmod 644 -R /home/\${LX_USERNAME}/.ssh/authorized_keys
EOF





# ---
# A VagrantBox is just a gzip tarball, as of
# the golang source code file 'image.go' of
# the terraform provider, and
#  https://developer.hashicorp.com/vagrant/docs/boxes/format
# - 
# 

if [ -f ./.base.box/debian12base.box ]; then
  rm ./.base.box/debian12base.box
fi;

# ---
# - [tar + gzip] = [tar -z]
# tar -zcvf ./.base.box/box.tar.gz ./.base.box/content
tar -zcvf ./.base.box/debian12base.box ./.base.box/content
# --- ---
# -- check the content of
# -  the box (a gzip tarball):
# --
# tar -tf ./.base.box/debian12base.box
tar -tf ./.base.box/debian12base.box
# -- ----