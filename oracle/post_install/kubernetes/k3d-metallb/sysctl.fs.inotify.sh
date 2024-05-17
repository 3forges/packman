#!/bin/bash

figlet 'fs inotify'

figlet 'before'
echo "Check value of [fs.inotify.max_user_instances]:"
sudo sysctl fs.inotify.max_user_instances
echo "Check value of [fs.inotify.max_user_watches]:"
sudo sysctl fs.inotify.max_user_watches


sudo sysctl fs.inotify.max_user_instances=8192
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl -p

cat /etc/sysctl.conf
cat /etc/sysctl.conf | grep inotify


echo '# - ##### ##### ##### ##### ' | sudo tee -a /etc/sysctl.conf
echo '# - ##### Configuration for ' | sudo tee -a /etc/sysctl.conf
echo '# - ## '
echo '# - ## kind, see: '
echo '# - ## '
echo '# - ## https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files'
echo '# - ## '
echo '# - ## Will avoid getting "too many open files"'
echo '# - ## error when running kubectl logs command'
echo '# - ## '
echo 'fs.inotify.max_user_instances=8192' | sudo tee -a /etc/sysctl.conf
echo 'fs.inotify.max_user_watches=524288' | sudo tee -a /etc/sysctl.conf

figlet 'after'
echo "Check value of [fs.inotify.max_user_instances]:"
sudo sysctl fs.inotify.max_user_instances
echo "Check value of [fs.inotify.max_user_watches]:"
sudo sysctl fs.inotify.max_user_watches

