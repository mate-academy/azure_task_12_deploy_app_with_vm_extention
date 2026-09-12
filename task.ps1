$location = "denmarkeast"
$resourceGroupName = "mate-azure-task-12"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "~/.ssh/id_rsa.pub" 
$publicIpAddressName = "linuxboxpip"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
$dnsLabel = "matetask" + (Get-Random -Count 1)
$vmAdminUsername = "azureuser"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

# Basic public IP SKU is retired; Standard + Static is required for new deployments.
New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Standard -AllocationMethod Static -DomainNameLabel $dnsLabel

# Credential supplies the Linux admin username; authentication uses -SshKeyName (not password login).
$securePassword = ConvertTo-SecureString "UnusedPassw0rd!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($vmAdminUsername, $securePassword)

New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $vmName `
-Location $location `
-image $vmImage `
-size $vmSize `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-PublicIpAddressName $publicIpAddressName `
-Credential $credential

# New-AzVm may replace NSG rules with a default SSH-only rule; ensure port 8080 stays open.
Write-Host "Ensuring NSG allows inbound traffic on port 8080 ..."
$nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Name $networkSecurityGroupName
$hasHttpRule = $nsg.SecurityRules | Where-Object {
    ($_.DestinationPortRange -eq "8080") -or ($_.DestinationPortRange -contains "8080")
}
if (-not $hasHttpRule) {
    Add-AzNetworkSecurityRuleConfig `
        -NetworkSecurityGroup $nsg `
        -Name HTTP `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority 1002 `
        -SourceAddressPrefix * `
        -SourcePortRange * `
        -DestinationAddressPrefix * `
        -DestinationPortRange 8080 `
        -Access Allow | Out-Null
    Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg | Out-Null
}

# ↓↓↓ Write your code here ↓↓↓
$installScriptUri = "https://raw.githubusercontent.com/Petliuk/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh"
$extensionSettings = @{
    "fileUris"         = @($installScriptUri)
    "commandToExecute" = "./install-app.sh"
}

Write-Host "Installing Custom Script VM extension..."
Set-AzVMExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Name "CustomScript" `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "CustomScript" `
    -TypeHandlerVersion "2.1" `
    -Location $location `
    -Settings $extensionSettings
