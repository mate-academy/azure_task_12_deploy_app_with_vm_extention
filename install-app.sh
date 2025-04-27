#!/bin/bash
apt-get update -yq
export DEBIAN_FRONTEND=noninteractive
apt-get install python3-pip -yq
mkdir -p /app

git clone https://github.com/trinidaa/azure_task_12_deploy_app_with_vm_extention
cp -r /azure_task_12_deploy_app_with_vm_extention/app/* /app/
mv /app/todoapp.service /etc/systemd/system/
rm -rf /azure_task_12_deploy_app_with_vm_extention
chmod +x /app/start.sh
chmod 644 /etc/systemd/system/todoapp.service
chown root:root /etc/systemd/system/todoapp.service
systemctl daemon-reload
systemctl enable todoapp.service
systemctl start todoapp.service