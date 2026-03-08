#!/bin/bash
set -euo pipefail

REPO_URL="${1:-}"
if [ -z "$REPO_URL" ]; then
  echo "Repository URL argument is required."
  exit 1
fi

# Script to silently install and start the todo web app on the virtual machine. 
# Note that all commands bellow are without sudo - that's because extention mechanism 
# runs scripts under root user. 

# install system updates and install required packages using apt. '-yq' flags are 
# used to suppress any interactive prompts - we won't be able to confirm operation 
# when running the script as VM extention.  
apt-get update -yq
apt-get install python3-pip git -yq

# Create a directory for the app and download the files from repo fork.
rm -rf /app
mkdir -p /app
rm -rf /tmp/azure_task_12_deploy_app_with_vm_extention
git clone "$REPO_URL" /tmp/azure_task_12_deploy_app_with_vm_extention
cp -r /tmp/azure_task_12_deploy_app_with_vm_extention/app/* /app
chmod +x /app/start.sh

# create a service for the app via systemctl and start the app
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp
