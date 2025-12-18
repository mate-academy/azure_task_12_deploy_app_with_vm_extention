#!/usr/bin/env bash
set -euo pipefail

# VM Extension runs as root -> no sudo
export DEBIAN_FRONTEND=noninteractive

: "${GITHUB_USER:?GITHUB_USER is not set (task.ps1 must pass it)}"

REPO_NAME="azure_task_12_deploy_app_with_vm_extention"
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"

APP_DIR="/app"
REPO_DIR="/tmp/${REPO_NAME}"

echo "[1/7] Update apt and install packages"
apt-get update -yq
apt-get install -yq git python3 python3-pip

echo "[2/7] Clone repo"
rm -rf "${REPO_DIR}"
git clone --depth 1 "${REPO_URL}" "${REPO_DIR}"

echo "[3/7] Validate repo structure"
if [ ! -d "${REPO_DIR}/app" ]; then
  echo "ERROR: '${REPO_DIR}/app' not found. Repo must contain 'app' folder."
  ls -la "${REPO_DIR}" || true
  exit 1
fi

if [ ! -f "${REPO_DIR}/app/todoapp.service" ]; then
  echo "ERROR: '${REPO_DIR}/app/todoapp.service' not found."
  ls -la "${REPO_DIR}/app" || true
  exit 1
fi

echo "[4/7] Copy app files to /app"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}"
cp -a "${REPO_DIR}/app/." "${APP_DIR}/"

echo "[5/7] Install python deps (if requirements.txt exists)"
if [ -f "${APP_DIR}/requirements.txt" ]; then
  pip3 install --no-input -r "${APP_DIR}/requirements.txt"
fi

echo "[6/7] Install and start systemd service"
install -m 0644 "${APP_DIR}/todoapp.service" /etc/systemd/system/todoapp.service
systemctl daemon-reload
systemctl enable --now todoapp

echo "[7/7] Service status"
systemctl --no-pager --full status todoapp || true
