#!/bin/bash

#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
################ IPTABLES SETUP
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################



sudo apt-get update -y

# -- I saw this:
sudo iptables -I INPUT -p tcp -m tcp --dport 9001 -j ACCEPT 
# comment option not available in Oracle's Ubuntu # --comment "CUSTOM: allow ingress (see OracleCloud SecurityList for instance's subnet), for Minio"
sudo iptables -I INPUT -p tcp -m tcp --dport 8888 -j ACCEPT  
# comment option not available in Oracle's Ubuntu # --comment "CUSTOM: allow ingress (see OracleCloud SecurityList for instance's subnet), for JupyterLab"
sudo netfilter-persistent save

sudo netfilter-persistent save

sudo iptables -L


#########################################################
#########################################################
#########################################################
#########################################################
#########################################################
################ DOCKER INSTALLATION
#########################################################
#########################################################
#########################################################
#########################################################
#########################################################




# Add Docker's official GPG key:
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true

# sudo groupadd docker || true

sudo usermod -aG docker $USER

# sudo reboot -h now # this just stops terraform state, it has to be done manually


