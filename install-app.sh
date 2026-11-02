#!/bin/bash
apt-get update -yq
apt-get install python3-pip dos2unix git -yq
git clone https://github.com/baga090/azure_task_12_deploy_app_with_vm_extention.git /repo
mkdir -p /app
cp -r /repo/app/* /app/
cd /app
dos2unix *
dos2unix todoapp.service
pip3 install -r requirements.txt --break-system-packages
mv todoapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp