#!/bin/bash

# Script to silently install and start the todo web app on the virtual machine. 
# Note that all commands bellow are without sudo - that's because extention mechanism 
# runs scripts under root user. 

# install system updates and isntall python3-pip package using apt. '-yq' flags are 
# used to suppress any interactive prompts - we won't be able to confirm operation 
# when running the script as VM extention.  
apt-get update -yq
apt-get install -yq git python3 python3-venv

git clone https://github.com/prostoponchik/azure_task_12_deploy_app_with_vm_extention.git

mkdir -p /app
cp -r azure_task_12_deploy_app_with_vm_extention/app/* /app

python3 -m venv /app/.venv

mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now todoapp
