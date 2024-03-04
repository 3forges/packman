#!/bin/bash
checkEnv () {
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- # --- # --- # --- # --- # --- "
    echo " [$0] checkEnv ()"
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- # --- # --- # --- # --- # --- "
    echo " [$0] DOCKER_DEBIAN_VERSION_STRING=[${DOCKER_DEBIAN_VERSION_STRING}]"
    echo " [$0] DESIRED_DOCKER_COMPOSE_VERSION=[${DESIRED_DOCKER_COMPOSE_VERSION}]"
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- # --- # --- # --- # --- # --- "
}
checkEnv

export DESIRED_DOCKER_COMPOSE_VERSION=${DESIRED_DOCKER_COMPOSE_VERSION:-"2.24.5"}
wget  https://github.com/docker/compose/releases/download/v${DESIRED_DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)
sudo mv ./docker-compose-$(uname -s)-$(uname -m) /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
export PATH=$PATH:/usr/bin/docker-compose
echo "export PATH=$PATH:/usr/bin/docker-compose" | sudo tee -a /etc/profile | tee -a $HOME/.profile | tee -a $HOME/.bash_profile
docker-compose --version