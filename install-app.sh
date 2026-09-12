#!/bin/bash

# Script to silently install and start the todo web app on the virtual machine.

apt-get update -yq
apt-get install python3-pip git -yq

# Create a directory for the app and download the files.
mkdir -p /app 

# Розкоментований рядок із GitHub username:
git clone https://github.com/Nick-Ptrnko/azure_task_12_deploy_app_with_vm_extention.git

cp -r azure_task_12_deploy_app_with_vm_extention/app/* /app/

# create a service for the app via systemctl and start the app
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp
