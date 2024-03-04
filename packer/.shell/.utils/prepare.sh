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
#!/bin/bash

export LX_USERNAME=${VAGRANT_LX_USER_NAME}
mkdir -p /home/\${LX_USERNAME}/.ssh/
echo '$VAGRANT_LX_USER_SSH_PUBKEY' | tee -a /home/\${LX_USERNAME}/.ssh/authorized_keys
chmod 700 -R /home/\${LX_USERNAME}/.ssh/
chmod 644 -R /home/\${LX_USERNAME}/.ssh/authorized_keys
sudo apt-get install -y curl wget gettext jq

EOF

export ALL_PACKMAN_LX_USERS_SSH_PUBKEY=$(cat ./.ssh.packman/id_rsa.pub)
if [ -f ./.shell/.build/create.lx.users.sh ]; then
  rm -f ./.shell/.build/create.lx.users.sh
fi;
cat ./.shell/.utils/create.lx.users.template.sh | tee ./.shell/.build/create.lx.users.sh
sed -i "s#ALL_PACKMAN_LX_USERS_SSH_PUBKEY_PLACEHOLDER#${ALL_PACKMAN_LX_USERS_SSH_PUBKEY}#g" ./.shell/.build/create.lx.users.sh

cp ./.shell/.utils/install-containerstack.sh ./.shell/.build/
cp ./.shell/.utils/install-docker.compose.sh ./.shell/.build/

chmod +x ./.shell/.build/*.sh

cat <<EOF >./addon.to.ssh.config
######################################################
# Vagrant
######################################################

Host 192.168.*.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host 127.0.0.1
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host local.*.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host *.loc
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

cat ./addon.to.ssh.config | tee -a ~/.ssh/config

rm ./addon.to.ssh.config


exit 0
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
# tar -zcvf ./.base.box/debian12base.box ./.base.box/content
# because of [https://github.com/hashicorp/vagrant/issues/12829]
tar -cvf ./.base.box/debian12base.box --exclude='.fake' --exclude='*.*.fake' --exclude='*.fake' ./.base.box/content
# --
# also both very useful, and clear, the bible: https://www.gnu.org/software/tar/manual/html_node/exclude.html
# --- ---
# -- check the content of
# -  the box (a gzip tarball):
# --
# tar -tf ./.base.box/debian12base.box
tar -tf ./.base.box/debian12base.box
# -- ----