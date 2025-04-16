#!/bin/bash
# Script to silently install and start the todo web app on the virtual machine.
# Note that all commands below are without sudo - that's because extension mechanism
# runs scripts under root user.
# Set environment to noninteractive to avoid prompts
export DEBIAN_FRONTEND=noninteractive
# Install system updates and install python3-pip package using apt.
# '-yq' flags suppress interactive prompts.
apt-get update -yq
apt-get install python3-pip -yq
# Create a directory for the app and download the files.
mkdir -p /app
# Make sure to uncomment the line below and update the link with your GitHub username
git clone https://github.com/konstantinou77/azure_task_12_deploy_app_with_vm_extention.git
cp -r azure_task_12_deploy_app_with_vm_extention/app/* /app/
# Create a service for the app via systemctl and start the app
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp

