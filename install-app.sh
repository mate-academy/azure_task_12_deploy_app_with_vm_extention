#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

REPOSITORY_URL="https://github.com/aleksandrmajlo/azure_task_12_deploy_app_with_vm_extention.git"
REPOSITORY_BRANCH="azure-majlo"
TEMP_DIRECTORY="/tmp/azure_task_12_deploy_app_with_vm_extention"
APP_DIRECTORY="/app"

echo "Installing required packages..."

apt-get update -yq
apt-get install -yq python3-pip git

echo "Downloading application from GitHub..."

rm -rf "$TEMP_DIRECTORY"
rm -rf "$APP_DIRECTORY"

git clone \
    --branch "$REPOSITORY_BRANCH" \
    --single-branch \
    "$REPOSITORY_URL" \
    "$TEMP_DIRECTORY"

echo "Copying application files..."

mkdir -p "$APP_DIRECTORY"
cp -r "$TEMP_DIRECTORY/app/." "$APP_DIRECTORY/"

chmod +x "$APP_DIRECTORY/start.sh"

echo "Configuring systemd service..."

mv "$APP_DIRECTORY/todoapp.service" /etc/systemd/system/todoapp.service

systemctl daemon-reload
systemctl enable todoapp
systemctl start todoapp

echo "Application deployment completed."