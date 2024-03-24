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

