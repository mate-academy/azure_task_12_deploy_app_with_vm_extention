# Create a Virtual Machine with Powershell

VMs are deployed with the script, you can deploy as many VMs as you need just by updating one script variable, but you still need to connect to the VM with SSH and install the app manually. Well, today we are going to fix it! 

In this task you will learn how to use VM extention to automate deployment of your app to the VM. The result script will allow you to deploy a VM and install the todo web app to it without any manuall actions, only by running the Powershell script. 

## How to complete tasks in this module 

Tasks in this module are relying on 2 PowerShell scripts: 

- `scripts/generate-artifacts.ps1` generates the task "artifacts" and uploads them to cloud storage. An "artifact" is evidence of a task completed by you. Each task will have its own script, which will gather the required artifacts. The script also adds a link to the generated artifact in the `artifacts.json` file in this repository — make sure to commit changes to this file after you run the script. 
- `scripts/validate-artifacts.ps1` validates the artifacts generated by the first script. It loads information about the task artifacts from the `artifacts.json` file.

Here is how to complete tasks in this module:

1. Clone task repository

2. Make sure you completed steps, described in the Prerequisites section

3. Complete the task, described in the Requirements section 

4. Run `scripts/generate-artifacts.ps1` to generate task artifacts. Script will update the file `artifacts.json` in this repo. 

5. Run `scripts/validate-artifacts.ps1` to test yourself. If tests are failing - follow the recomendation from the test script error message to fix or re-deploy your infrastructure. When you will be ready to test yourself again - **re-generate the artifacts** (step 4) and re-run tests again. 

6. When all tests will pass - commit your changes and submit the solution for a review. 

Pro tip: if you stuck with any of the implementation steps - run `scripts/generate-artifacts.ps1` and `scripts/validate-artifacts.ps1`. The validation script might give you a hint on what you should do.  

## Prerequisites

Before completing any task in the module, make sure that you followed all the steps described in the **Environment Setup** topic, in particular: 

1. Ensure you have an [Azure](https://azure.microsoft.com/en-us/free/) account and subscription.

2. Create a resource group called *"mate-resources"* in the Azure subscription.

3. In the *"mate-resources"* resource group, create a storage account (any name) and a *"task-artifacts"* container.

4. Install [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4) on your computer. All tasks in this module use Powershell 7. To run it in the terminal, execute the following command: 
    ```
    pwsh
    ```

5. Install [Azure module for PowerShell 7](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-11.3.0): 
    ```
    Install-Module -Name Az -Repository PSGallery -Force
    ```
If you are a Windows user, before running this command, please also run the following: 
    ```
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

6. Log in to your Azure account using PowerShell:
    ```
    Connect-AzAccount -TenantId <your Microsoft Entra ID tenant id>
    ```

## Requirements

In this task, you will need to write and run a Powershell script, which deploys a virtual machines and uses custom script VM extention to deploy a web app:  

1. Write your script code to the file `task.ps1` in this repository:

    - In script, you should assume that you are already logged in to Azure and using correct subscription (don't use commands 'Connect-AzAccount' and 'Set-AzContext', if needed - just run them on your computer before running the script).

    - Script already have code, which deploys a VM. Update the code so it will deploy a web app from this repo using a custom script VM extention.

    - To deploy an extention, use [Set-AzVMExtention](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/features-linux?tabs=azure-powershell#azure-powershell-1) comandlet.

    - Extention should run a script `install-app.sh`, which should be loaded from your fork of this repo. In your for, the script will be available by the URL: `https://raw.githubusercontent.com/<your-github-username>/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh`

    - Make sure to review and update script `install-app.sh` - it should clone your fork of this repo to the VM. Take a note, that as `install-app.sh` will be downloaded by your VM from the GitHub, you need to commit and push changes to it before running the Powershell code which deploys the extention.

2. When script is ready, run it to deploy resources to your subcription. Make sure that script is working without errors, and that application is available on port 8080 after you run the script. To verify that web application is running, open in a web browser the following URL: `http://<your-public-ip-DNS-name>:8080`.

3. Run artifacts generation script `scripts/generate-artifacts.ps1`.

4. Test yourself using the script `scripts/validate-artifacts.ps1`.

5. Make sure that changes to both `task.ps1` and `result.json` are commited to the repo, and sumbit the solution for a review.

6. When solution is validated, delete resources you deployed with the powershell script - you won't need them for the next tasks.
