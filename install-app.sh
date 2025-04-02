#!/bin/bash

# Script to silently install and start the todo web app on the virtual machine. 
# Note that all commands bellow are without sudo - that's because extention mechanism 
# runs scripts under root user. 

# install system updates and install python3-pip package using apt. '-yq' flags are
# used to suppress any interactive prompts - we won't be able to confirm operation
# when running the script as VM extension.
apt-get update -yq
apt-get install python3-pip -yq

# Create a directory for the app and download the files.
mkdir /app
git clone https://github.com/beliar24/azure_task_12_deploy_app_with_vm_extention.git

# Переходим в директорию с репозиторием
cd azure_task_12_deploy_app_with_vm_extention/app || exit 1

# Копируем содержимое папки app в /app
cp -r . /app

# create a service for the app via systemctl and start the app
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp
