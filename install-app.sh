#!/bin/bash

# Script to silently install and start the todo web app on the virtual machine.
# Extension mechanism runs scripts as root, so sudo is not required.

# Install system packages.
apt-get update -yq
apt-get install python3-pip -yq

# Create a directory for the app.
mkdir -p /app

# Clone the application repository.
git clone https://github.com/tetianamohorian23/azure_task_12_deploy_app_with_vm_extention.git

# Copy application files.
cp -r azure_task_12_deploy_app_with_vm_extention/app/* /app

# Install Python dependencies.
pip3 install -r /app/requirements.txt

# Create and start the app service.
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp