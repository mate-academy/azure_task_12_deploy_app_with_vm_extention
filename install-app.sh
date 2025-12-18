#!/bin/bash
set -euo pipefail

# VM Extension runs as root -> no sudo needed

GITHUB_USER="KyryloKilin"
REPO_NAME="azure_task_12_deploy_app_with_vm_extention"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

APP_DIR="/app"
REPO_DIR="/tmp/${REPO_NAME}"

echo "[1/7] Update apt and install packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -yq
apt-get install -yq git python3-pip

echo "[2/7] Prepare app dir"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}"

echo "[3/7] Clone repo"
rm -rf "${REPO_DIR}"
git clone "${REPO_URL}" "${REPO_DIR}"

echo "[4/7] Check repo structure"
if [[ ! -d "${REPO_DIR}/app" ]]; then
  echo "ERROR: '${REPO_DIR}/app' not found. Repo structure must contain /app folder."
  ls -la "${REPO_DIR}" || true
  exit 1
fi

echo "[5/7] Copy app files to /app"
cp -r "${REPO_DIR}/app/"* "${APP_DIR}/"

echo "[6/7] Install python deps (if requirements.txt exists)"
if [[ -f "${APP_DIR}/requirements.txt" ]]; then
  pip3 install -r "${APP_DIR}/requirements.txt"
fi

echo "[7/7] Install and start systemd service"
if [[ ! -f "${APP_DIR}/todoapp.service" ]]; then
  echo "ERROR: '${APP_DIR}/todoapp.service' not found after copy."
  ls -la "${APP_DIR}" || true
  exit 1
fi

mv -f "${APP_DIR}/todoapp.service" /etc/systemd/system/todoapp.service
systemctl daemon-reload
systemctl enable --now todoapp
systemctl restart todoapp

echo "DONE. Service status:"
systemctl --no-pager --full status todoapp || true
