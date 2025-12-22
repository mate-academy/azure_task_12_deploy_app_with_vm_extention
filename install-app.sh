#!/bin/bash

# Script to silently install and start the todo web app on the virtual machine. 
# Note that all commands bellow are without sudo - that's because extention mechanism 
# runs scripts under root user. 

# install system updates and install python3-pip package using apt. '-yq' flags are
# used to suppress any interactive prompts - we won't be able to confirm operation
# when running the script as VM extention.
apt-get update -yq
apt-get install python3-pip git -yq

# Create a directory for the app and download the files.
cd /tmp
# Clone your fork of the repository
# Replace <your-gh-username> with your actual GitHub username
git clone https://github.com/TymurProkhorov/azure_task_12_deploy_app_with_vm_extention.git

# Copy app files to /app directory
mkdir -p /app
cp -r azure_task_12_deploy_app_with_vm_extention/app/* /app

# Install Python dependencies if requirements.txt exists
if [ -f /app/requirements.txt ]; then
    pip3 install -r /app/requirements.txt
fi

# create a service for the app via systemctl and start the app
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp

echo "Application deployed and started successfully"