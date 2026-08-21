#!/bin/bash

# Script to silently install and start the todo web app on the virtual machine.
# VM extension runs this script as root, so sudo is not required.

apt-get update -yq
apt-get install python3-pip -yq
apt-get install git -yq

# Create a directory for the app and clone the repository
mkdir -p /app

git clone https://github.com/Loki-sudo007/azure_task_12_deploy_app_with_vm_extention.git

cp -r azure_task_12_deploy_app_with_vm_extention/app/* /app

# Create a service for the app via systemctl and start the app
mv /app/todoapp.service /etc/systemd/system/

systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp