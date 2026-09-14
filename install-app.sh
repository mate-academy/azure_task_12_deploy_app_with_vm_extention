#!/bin/bash
apt-get update -yq
apt-get install python3-pip -yq
mkdir -p /app
git clone https://github.com/nook17n1/azure_task_12_deploy_app_with_vm_extention.git /app/repo
cp -r /app/repo/app/* /app
mv /app/todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp
