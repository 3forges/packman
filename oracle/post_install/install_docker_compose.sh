#!/bin/bash
# ------
#  Ubuntu-22.04-Minimal-aarch64
#########################################################
#########################################################
#########################################################

export DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-"v2.26.1"}

# export DOWNLOAD_LINK="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-armv7"
export DOWNLOAD_LINK="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64"
curl -LO ${DOWNLOAD_LINK}

sudo mkdir -p /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/

# sudo mv ./docker-compose-linux-armv7 /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/
sudo mv ./docker-compose-linux-aarch64 /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/

# chmod +x /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-armv7
chmod +x /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64

# /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-armv7 version
/usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64 version

# sudo ln -s /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-armv7 /usr/bin/docker-compose

#sudo cp /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-armv7 /usr/bin/
sudo cp /usr/bin/docker-compose/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-aarch64 /usr/bin/

# sudo cp -f /usr/bin/docker-compose-linux-armv7 /usr/bin/docker-compose
sudo cp -f /usr/bin/docker-compose-linux-aarch64 /usr/bin/docker-compose
sudo cp -f /usr/bin/docker-compose-linux-aarch64 /usr/local/bin/docker-compose

sudo chmod +x /usr/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "#########################################################"
echo "################ which bash gives: [$(which bash)]"
echo "#########################################################"

echo "#########################################################"
echo "################ DOCKER-COMPOSE INSTALLATION COMPLETE!"
echo "#########################################################"
export PATH="$PATH:/usr/bin:/usr/bin/docker-compose:/usr/local/bin/docker-compose"
echo 'export PATH="$PATH:/usr/bin:/usr/bin/docker-compose:/usr/local/bin/docker-compose"' | tee -a ~/.bashrc  | tee -a ~/.shrc | tee -a ~/.profile | sudo tee -a /etc/.profile
echo 'alias docker-compose=/usr/local/bin/docker-compose' | tee -a ~/.bashrc  | tee -a ~/.shrc | tee -a ~/.profile | sudo tee -a /etc/.profile
alias docker-compose=/usr/local/bin/docker-compose
source ~/.bashrc
/usr/local/bin/docker-compose version
docker-compose version || true