#!/bin/bash
set -euo pipefail

# Script to silently install and start the todo web app on the virtual machine.
# Note: VM Extension runs this script as root, so we don't use sudo.

APP_DIR="/app"
REPO_DIR="/tmp/azure_task_12_repo"
GITHUB_USER="KyryloKilin"
REPO_URL="https://github.com/${GITHUB_USER}/azure_task_12_deploy_app_with_vm_extention.git"

echo "[1/6] Install system updates and required packages"
apt-get update -yq
apt-get install -yq python3-pip python3-venv git

echo "[2/6] Prepare app directory"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}"

echo "[3/6] Clone repo with app files"
rm -rf "${REPO_DIR}"
git clone "${REPO_URL}" "${REPO_DIR}"

# В репо по заданию обычно есть папка app/ с файлами приложения и unit-файлом todoapp.service
if [ ! -d "${REPO_DIR}/app" ]; then
  echo "ERROR: '${REPO_DIR}/app' not found. Check your repository structure."
  exit 1
fi

echo "[4/6] Copy app files to /app"
cp -r "${REPO_DIR}/app/"* "${APP_DIR}/"

echo "[5/6] Install Python dependencies (if requirements.txt exists)"
if [ -f "${APP_DIR}/requirements.txt" ]; then
  pip3 install -q -r "${APP_DIR}/requirements.txt"
fi

echo "[6/6] Install and start systemd service"
if [ ! -f "${APP_DIR}/todoapp.service" ]; then
  echo "ERROR: '${APP_DIR}/todoapp.service' not found."
  exit 1
fi

# На всякий случай: если в unit-файле путь относительный/неправильный — ты это уже увидишь в systemctl status
mv -f "${APP_DIR}/todoapp.service" /etc/systemd/system/todoapp.service

systemctl daemon-reload
systemctl enable todoapp
systemctl restart todoapp

echo "DONE. Service status:"
systemctl --no-pager --full status todoapp || true
