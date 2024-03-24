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

# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- 
# -- Except the line marked 'NOT TESTED YET',  I tested all
#    those possibilities, with all of them, even the last ones
#    not commented, I can't access my webapp minio on port 9001:
# -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- 
# KO # sudo iptables -I INPUT -p tcp -m tcp --dport 9001 -j ACCEPT 
# KO # sudo iptables -I INPUT -m state --state NEW -p tcp --dport 9001 -j ACCEPT
# KO # sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 9001 -j ACCEPT
sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport 9001 -j ACCEPT -m comment --comment "CUSTOM: allow ingress (see OracleCloud SecurityList for instance's subnet), for Minio"
# NOT TESTED YET # sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport 9001 -j ACCEPT
# comment option not available in Oracle's Ubuntu # --comment "CUSTOM: allow ingress (see OracleCloud SecurityList for instance's subnet), for Minio"
# KO # sudo iptables -I INPUT -p tcp -m tcp --dport 8888 -j ACCEPT  
# KO # sudo iptables -I INPUT -m state --state NEW -p tcp --dport 8888 -j ACCEPT
# KO # sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 8888 -j ACCEPT
sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport 8888 -j ACCEPT -m comment --comment "CUSTOM: allow ingress (see OracleCloud SecurityList for instance's subnet), for JupyterLab"
# NOT TESTED YET # sudo iptables -I INPUT 5 -m state --state NEW -p tcp --dport 8888 -j ACCEPT
# comment option not available in Oracle's Ubuntu # --comment "CUSTOM: allow ingress (see OracleCloud SecurityList for instance's subnet), for JupyterLab"
sudo netfilter-persistent save

sudo iptables -L

