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


# --- 
# --- # --- 
# --- # --- # --- 
# - Uninstall old versions of Docker
# - Uninstall any Conflicting packages
# - Uninstall also current versions of Docker
# --
# - Does not delete existing containers, images, and volumes
# --- # --- # --- 
# --- # --- 
# --- 
softUninstallDocker () {
export PKG_LIST="docker.io docker-doc docker-compose podman-docker containerd runc"
for pkg in ${PKG_LIST}; do sudo apt-get -y --purge remove $pkg; done

echo " # --- # --- # --- # --- # --- # --- "
echo " # --- # --- # --- # --- # --- # --- "
echo " > apt-get might report that you have none of the"
echo " >  [${PKG_LIST}]"
echo " > packages installed."
echo " # --- # --- # --- # --- # --- # --- "
echo " # --- # --- # --- # --- # --- # --- "

export PKG_LIST="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras"
sudo apt-get -y purge ${PKG_LIST}

echo " # --- # --- # --- # --- # --- # --- "
echo " # --- # --- # --- # --- # --- # --- "
echo " > apt-get might report that you have none of the"
echo " >  [${PKG_LIST}]"
echo " > packages installed."
echo " # --- # --- # --- # --- # --- # --- "
echo " # --- # --- # --- # --- # --- # --- "
}

# --- 
# --- # --- 
# --- # --- # --- 
# - Uninstall old versions of Docker
# - Uninstall any Conflicting packages
# - Uninstall also current versions of Docker
# --
# - Also deletes existing containers, images, and volumes
# --- # --- # --- 
# --- # --- 
# --- 
hardUninstallDocker () {
softUninstallDocker
sudo rm -rf /var/lib/docker || true
sudo rm -rf /var/lib/containerd || true
}


setUpDockerAptGetRepository () {
# Add Docker's official GPG key:
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
}

installLatestDockerVersion () {
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

installSpecificDockerVersion () {
echo " # --- # --- # --- # --- # --- # --- "
echo " # --- # --- # --- # --- # --- # --- "
echo " List available Docker versions"
echo " # --- # --- # --- # --- # --- # --- "
echo " # --- # --- # --- # --- # --- # --- "
sudo apt-cache madison docker-ce | awk '{ print $3 }'
# - 
# --- - Example output:
# 5:25.0.0-1~debian.12~bookworm
# 5:24.0.7-1~debian.12~bookworm
# ...
# --- - 
# - 
# export DESIRED_DOCKER_VERSION=${DESIRED_DOCKER_VERSION:-"25.0.0"}
# export DOCKER_DEBIAN_VERSION_STRING="5:25.0.3-1~debian.12~bookworm"
export DOCKER_DEBIAN_VERSION_STRING=${DOCKER_DEBIAN_VERSION_STRING:-"5:25.0.0-1~debian.12~bookworm"}
sudo apt-get install -y docker-ce=${DOCKER_DEBIAN_VERSION_STRING} docker-ce-cli=${DOCKER_DEBIAN_VERSION_STRING} containerd.io docker-buildx-plugin docker-compose-plugin
}



checkEnv
softUninstallDocker
setUpDockerAptGetRepository
installSpecificDockerVersion
# --- 
# --- # --- 
# --- # --- # --- 
# Post Installation Steps
# --- # --- # --- 
# --- # --- 
# --- 
sudo groupadd docker || true
echo "# --- # --- # --- # --- # --- # --- "
echo "# - [$0] Add users to docker group"
echo "# --- # --- # --- # --- # --- # --- "
export DOCKER_USERS_LIST=${DOCKER_USERS_LIST:-"$(whoami)"}
for THAT_USER in ${DOCKER_USERS_LIST}; do sudo usermod -aG docker $THAT_USER; done

cat <<EOF >./final.notice.message
Log out and log back in so that your group membership is re-evaluated.
If you're running Linux in a virtual machine, it may be necessary to restart the virtual machine for changes to take effect.
EOF

checkEnv