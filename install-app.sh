#!/bin/bash

# Оновлення пакетів
sudo apt-get update

# Встановлення Git
sudo apt-get install -y git

# Встановлення Node.js
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

# Клонування репозиторію
git clone https://github.com/Yevgene-DP/azure_task_12_deploy_app_with_vm_extention.git /home/azureuser/app

# Перехід у директорію додатку
cd /home/azureuser/app

# Встановлення залежностей
npm install

# Запуск додатку (у фоновому режимі)
npm start &