$location = "denmarkeast"
$resourceGroupName = "mate-resources"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$sshKeyName = "linuxboxsshkey"
$publicIpAddressName = "linuxboxpip-task12"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B2s_v2"

$adminUsername = "azureuser"
$password = ConvertTo-SecureString "TempPassword123!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $password)

Write-Host "Using existing public IP $publicIpAddressName ..."
$publicIp = Get-AzPublicIpAddress `
    -ResourceGroupName $resourceGroupName `
    -Name $publicIpAddressName

Write-Host "Creating VM $vmName ..."
New-AzVm `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName `
    -Location $location `
    -Image $vmImage `
    -Size $vmSize `
    -SubnetName $subnetName `
    -VirtualNetworkName $virtualNetworkName `
    -SecurityGroupName $networkSecurityGroupName `
    -SshKeyName $sshKeyName `
    -PublicIpAddressName $publicIpAddressName `
    -Credential $credential

Write-Host "Installing Custom Script Extension ..."

$extensionSettings = @{
    fileUris = @(
        "https://raw.githubusercontent.com/tetianamohorian23/azure_task_12_deploy_app_with_vm_extention/develop/install-app.sh"
    )
    commandToExecute = "bash install-app.sh"
}

Set-AzVMExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Location $location `
    -Name "todoapp-extension" `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "CustomScript" `
    -TypeHandlerVersion "2.1" `
    -Settings $extensionSettings

Write-Host "Task 12 deployment completed."
