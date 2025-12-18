#!/bin/bash
set -euo pipefail

# VM Extension runs as root -> no sudo needed

GITHUB_USER="KyryloKilin"
REPO_NAME="azure_task_12_deploy_app_with_vm_extention"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

APP_DIR="/app"
REPO_DIR="/tmp/${REPO_NAME}"

echo "[1/6] Install packages"
apt-get update -yq
apt-get install -yq python3-pip git

echo "[2/6] Prepare folders"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}"
rm -rf "${REPO_DIR}"

echo "[3/6] Clone repo"
git clone "${REPO_URL}" "${REPO_DIR}"

echo "[4/6] Check repo structure"
if [ ! -d "${REPO_DIR}/app" ]; then
  echo "ERROR: '${REPO_DIR}/app' not found. Repo structure is wrong."
  exit 1
fi

echo "[5/6] Copy app files to /app"
cp -r "${REPO_DIR}/app/"* "${APP_DIR}/"

echo "[6/6] Install and start systemd service"
if [ ! -f "${APP_DIR}/todoapp.service" ]; then
  echo "ERROR: '${APP_DIR}/todoapp.service' not found after copy."
  exit 1
fi

mv -f "${APP_DIR}/todoapp.service" /etc/systemd/system/todoapp.service
systemctl daemon-reload
systemctl enable --now todoapp

echo "DONE"
systemctl --no-pager --full status todoapp || true
