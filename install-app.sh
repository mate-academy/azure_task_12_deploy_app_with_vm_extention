#!/bin/bash

# update packages
apt-get update -yq

# install dependencies
apt-get install python3-pip git -yq

# create app directory
mkdir /app

# clone your repository
git clone https://github.com/cnlgstcorp/azure_task_12_deploy_app_with_vm_extention.git

# copy application files
cp -r azure_task_12_deploy_app_with_vm_extention/app/* /app

# install python dependencies
pip3 install -r /app/requirements.txt

# install systemd service
mv /app/todoapp.service /etc/systemd/system/

# reload systemd
systemctl daemon-reload

# start application
systemctl start todoapp

# enable autostart
systemctl enable todoapp