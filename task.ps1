$location = "northcentralus"
$resourceGroupName = "mate-task-12-final-passed"
$vmName = "matebox-web"
$vmSize = "Standard_B1s"
$vmImage = "Ubuntu2204"
$sshKeyName = "linuxboxsshkey"

$githubUsername = "d4vp4"
$scriptUrl = "https://raw.githubusercontent.com/$githubUsername/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh"
$dnsLabel = "d4vp4-final-" + (Get-Random -Minimum 1000 -Maximum 9999)

New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

Write-Host "Creating SSH Key resource..." -ForegroundColor Cyan
New-AzSshKey -ResourceGroupName $resourceGroupName -Name $sshKeyName -Location $location

$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
    -Name "web-pip" -AllocationMethod Static -Sku Standard -DomainNameLabel $dnsLabel

$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "web-nsg" -SecurityRules @(
    New-AzNetworkSecurityRuleConfig -Name "SSH" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
    New-AzNetworkSecurityRuleConfig -Name "Web8080" -Protocol Tcp -Direction Inbound -Priority 1010 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
)

$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24" -NetworkSecurityGroup $nsg
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name "vnet" -AddressPrefix "10.0.0.0/16" -Subnet $subnetConfig

Write-Host "Creating VM ($vmSize)..." -ForegroundColor Yellow
$cred = Get-Credential -UserName "azureuser" -Message "Введи пароль для VM"

New-AzVM -ResourceGroupName $resourceGroupName `
    -Name $vmName `
    -Location $location `
    -VirtualNetworkName "vnet" `
    -SubnetName "default" `
    -SecurityGroupName "web-nsg" `
    -PublicIpAddressName "web-pip" `
    -Image $vmImage `
    -Size $vmSize `
    -Credential $cred `
    -SshKeyName $sshKeyName `
    -OpenPorts 22, 8080

Write-Host "Deploying Application..." -ForegroundColor Magenta
Set-AzVMExtension -ResourceGroupName $resourceGroupName `
    -Location $location `
    -VMName $vmName `
    -Name "InstallTodoApp" `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "CustomScript" `
    -TypeHandlerVersion "2.1" `
    -Settings @{
        "fileUris" = @($scriptUrl);
        "commandToExecute" = "bash install-app.sh"
    }