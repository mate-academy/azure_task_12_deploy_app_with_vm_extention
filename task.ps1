$location = "uksouth"
$resourceGroupName = "mate-azure-task-12"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "C:\Users\ipppk\.ssh\id_rsa.pub" -Raw
$publicIpAddressName = "linuxboxpip"
$vmName = "matebox"
$vmImage = "Canonical:UbuntuServer:18.04-LTS:latest"
$vmSize = "Standard_B1s"
$dnsLabel = "matetask" + (Get-Random -Count 1)

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Basic -AllocationMethod Dynamic -DomainNameLabel $dnsLabel

Write-Host "Creating network interface..."
$nic = New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Location $location -Name "${vmName}Nic" `
    -SubnetId (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName).Subnets[0].Id `
    -PublicIpAddressId (Get-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName).Id `
    -NetworkSecurityGroupId (Get-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName).Id

Write-Host "Creating VM $vmName ..."
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", (ConvertTo-SecureString "placeholderpassword" -AsPlainText -Force))
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | `
    Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred -DisablePasswordAuthentication | `
    Set-AzVMSourceImage -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts-gen2" -Version "latest" | `
    Add-AzVMNetworkInterface -Id $nic.Id | `
    Add-AzVMSSHPublicKey -KeyData $sshKeyPublicKey -Path "/home/azureuser/.ssh/authorized_keys"

Write-Host "Starting VM creation..."
$vm = New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

Write-Host "Waiting for VM to be fully provisioned..."
Start-Sleep -Seconds 60

# Перевірка стану VM
$vmState = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
if ($vmState.ProvisioningState -ne 'Succeeded') {
    Write-Host "VM is not in 'Succeeded' state. Current state: $($vmState.ProvisioningState)"
    exit
}

Write-Host "Adding CustomScript extension to VM..."
$scriptUrl = "https://raw.githubusercontent.com/ILyakhova/azure_task_12_deploy_app_with_vm_extention/develop/install-app.sh"
$publicSettings = @{
    "fileUris" = @($scriptUrl)
    "commandToExecute" = "sh install-app.sh"
}

try {
    Set-AzVMExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Name "CustomScriptExtension" `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "CustomScript" `
    -TypeHandlerVersion "2.0" `
    -SettingString (ConvertTo-Json $publicSettings)
    Write-Host "CustomScript extension added successfully."
} catch {
    Write-Host "Error adding CustomScript extension: $_"
    exit
}

Write-Host "Deployment complete. You can access your app at http://$($dnsLabel).uksouth.cloudapp.azure.com:8080"
