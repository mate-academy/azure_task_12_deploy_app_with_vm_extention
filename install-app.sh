#!/bin/bash

# Script to silently install and start the todo web app on the virtual machine. 
# Note that all commands bellow are without sudo - that's because extention mechanism 
# runs scripts under root user. 

set -euo pipefail

# install system updates and isntall python3-pip package using apt. '-yq' flags are 
# used to suppress any interactive prompts - we won't be able to confirm operation 
# when running the script as VM extention.  
apt-get update -yq
apt-get install git python3-pip -yq

# Create a directory for the app and download the files. 
rm -rf /app /tmp/azure-task-12-app
mkdir -p /app
git clone --depth 1 https://github.com/spridoloba/azure_task_12_deploy_app_with_vm_extention.git /tmp/azure-task-12-app
cp -r /tmp/azure-task-12-app/app/. /app
chmod +x /app/start.sh

# create a service for the app via systemctl and start the app
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp
