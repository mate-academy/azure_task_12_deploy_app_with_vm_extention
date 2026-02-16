#!/bin/bash
set -e

sudo apt-get update
sudo apt-get install -y python3 python3-pip git

sudo rm -rf /app
rm -rf temp_repo

sudo mkdir -p /app

git clone https://github.com/d4vp4/azure_task_12_deploy_app_with_vm_extention.git temp_repo

sudo cp -r temp_repo/app/* /app/

sudo pip3 install -r /app/requirements.txt

sudo cp /app/todoapp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable todoapp
sudo systemctl restart todoapp
