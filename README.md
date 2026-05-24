# Azure VM Deployment Automation with VM Extension

This project demonstrates fully automated deployment of a web application on an Azure Virtual Machine using PowerShell and Azure VM Extensions.

The solution eliminates manual configuration steps by provisioning a VM and automatically deploying a Django-based todo application via a custom script extension.

## Key Features
- Automated Azure VM provisioning using PowerShell
- Application deployment using Azure VM Extensions
- Fully hands-free installation process
- Deployment of a Django-based web application
- Systemd service configuration for application management
- Accessible web service on port 8080 after deployment

## Technologies
- Microsoft Azure (Virtual Machines, VM Extensions)
- PowerShell
- Bash scripting
- Linux (Ubuntu)
- Django (web application)
- systemd

## How it works
1. PowerShell script provisions an Azure VM
2. VM Extension downloads and executes installation script
3. Application is cloned and configured on the VM
4. Systemd service starts the web application automatically
5. Application becomes accessible via public IP on port 8080

## Result
A fully automated cloud deployment pipeline that provisions infrastructure and deploys a working web application with a single command.