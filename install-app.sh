#!/bin/bash
# Script to silently install and start the todo web app on the virtual machine.
# Note that all commands below are without sudo - that's because the extension mechanism 
# runs scripts under the root user. 

# Update system and install required packages
apt-get update -yq
apt-get install -yq python3-pip git

# Define variables
APP_DIR="/app"
REPO_URL="https://github.com/kostiukmkalne/azure_task_12_deploy_app_with_vm_extention.git"

echo "Cloning the application repository..."
# Remove the directory if it exists
rm -rf $APP_DIR
mkdir $APP_DIR

# Clone the repo and move the files
git clone $REPO_URL /tmp/app_repo
cp -r /tmp/app_repo/app/* $APP_DIR
rm -rf /tmp/app_repo

# Set up and start the service
mv $APP_DIR/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp

echo "Application deployment completed successfully."
