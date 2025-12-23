$location = "eastus"
$resourceGroupName = "mate-azure-task-12"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "~/.ssh/id_ed25519.pub"
$publicIpAddressName = "linuxboxpip"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_DC1s_v3"
$dnsLabel = "matetask" + (Get-Random -Count 1)

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP -Force

Write-Host "Creating virtual network..."
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet -Force

Write-Host "Creating SSH key..."
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey -ErrorAction SilentlyContinue

Write-Host "Creating public IP address..."
New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Standard -AllocationMethod Static -DomainNameLabel $dnsLabel -Force

Write-Host "Creating virtual machine..."
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
    -PublicIpAddressName $publicIpAddressName

# ↓↓↓ Write your code here ↓↓↓

Write-Host "Deploying Custom Script Extension to install the web app..."

$githubUsername = "TymurProkhorov"
$scriptUrl = "https://raw.githubusercontent.com/$githubUsername/azure_task_12_deploy_app_with_vm_extention/deploy-app-via-extension/install-app.sh"

# Wait a bit for VM to be fully ready
Start-Sleep -Seconds 30

# Configure and deploy the Custom Script Extension
Set-AzVMExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Name "CustomScriptExtension" `
    -Publisher "Microsoft.Azure.Extensions" `
    -Type "CustomScript" `
    -TypeHandlerVersion "2.1" `
    -Settings @{"fileUris" = @($scriptUrl)} `
    -ProtectedSettings @{"commandToExecute" = "bash install-app.sh"} `
    -Location $location
