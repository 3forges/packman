#!/bin/bash

checkEnv () {
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- CREATE LX USERS "
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- # --- # --- # --- # --- # --- "
    echo " [$0] checkEnv ()"
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- # --- # --- # --- # --- # --- "
    echo " [$0] LX_USERS_TO_CREATE=[${LX_USERS_TO_CREATE}]"
    echo " [$0] NEW_LX_USERS_GRP_NAME=[${NEW_LX_USERS_GRP_NAME}]"
    echo " [$0] NEW_LX_USERS_GRP_GID=[${NEW_LX_USERS_GRP_GID}]"
    echo " [$0] NEW_LX_USERS_START_UID=[${NEW_LX_USERS_START_UID}]"
    echo " [$0] NEW_LX_USERS_EXTRA_GROUPS=[${NEW_LX_USERS_EXTRA_GROUPS}]"
    echo " # --- # --- # --- # --- # --- # --- "
    echo " # --- # --- # --- # --- # --- # --- "
}

export LX_USERS_TO_CREATE=${LX_USERS_TO_CREATE:-"$(whoami)"}

# - The group for all users to create, named packman by default
export NEW_LX_USERS_GRP_NAME=${NEW_LX_USERS_GRP_NAME:-"packman"}
export NEW_LX_USERS_GRP_GID=${NEW_LX_USERS_GRP_GID:-"1010"}
export NEW_LX_USERS_START_UID=${NEW_LX_USERS_START_UID:-"1010"}
# ---
# eg. you could have the docker linux users group, etc...
export NEW_LX_USERS_EXTRA_GROUPS=${NEW_LX_USERS_EXTRA_GROUPS:-""}

checkEnv

# --- # --- # --- # --- # --- 
# --- # --- # --- # --- # --- 
# --- # START OPS
# --- # --- # --- # --- # --- 
# --- # --- # --- # --- # --- 

# --- # --- # --- 
#  First create 
#  the group of 
#  all users
# --- # --- # --- 
sudo groupadd -g $NEW_LX_USERS_GRP_GID $NEW_LX_USERS_GRP_NAME

# --- # --- # --- 
#  Then create 
#  create 
#  all users
# --- # --- # --- 
export THAT_USER_UID=$NEW_LX_USERS_START_UID

for THAT_USER in ${LX_USERS_TO_CREATE}; do
  export THAT_USER_UID=$((THAT_USER_UID+1))
  echo ">>> # >>> # >>> # >>> # >>> # >>> # >>> # "
  echo ">>> # >>> # >>> # >>> # >>> # >>> # >>> # "
  echo ">>> # Create the [${THAT_USER}] user "
  echo ">>>   sudo useradd -g $NEW_LX_USERS_GRP_NAME -u $THAT_USER_UID -m $THAT_USER"
  echo ">>> # >>> # >>> # >>> # >>> # >>> # >>> # "
  echo ">>> # >>> # >>> # >>> # >>> # >>> # >>> # "
  # create the user
  sudo useradd -g $NEW_LX_USERS_GRP_NAME -u $THAT_USER_UID -m $THAT_USER
  # add the user to the sudo group
  sudo usermod -aG sudo $THAT_USER || true
  # to the SSH setup
  sudo mkdir -p /home/${THAT_USER}/.ssh/
  echo 'ALL_PACKMAN_LX_USERS_SSH_PUBKEY_PLACEHOLDER' | sudo tee -a /home/${LX_USERNAME}/.ssh/authorized_keys
  chmod 700 -R /home/${THAT_USER}/.ssh/
  chmod 644 -R /home/${THAT_USER}/.ssh/authorized_keys
done

# --- # --- # --- 
#  Then add 
#  all users
#  to extra groups
# --- # --- # --- 
for THAT_USER in ${LX_USERS_TO_CREATE}; do
    for THAT_EXTRA_GROUP in ${NEW_LX_USERS_EXTRA_GROUPS}; do
      echo ">>> # >>> # >>> # >>> # >>> # >>> # >>> # "
      echo ">>> # Add the [${THAT_USER}}] user to the [${THAT_EXTRA_GROUP}] linux users group"
      echo ">>> # >>> # >>> # >>> # >>> # >>> # >>> # "
      # add the user to the extra group
      sudo usermod -aG $THAT_EXTRA_GROUP $THAT_USER || true
    done
done