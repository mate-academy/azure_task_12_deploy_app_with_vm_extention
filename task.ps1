$ErrorActionPreference = "Stop"

# Main configuration
$location = "indiasouthcentral"
$resourceGroupName = "mate-azure-task-12"

# Network configuration
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"

$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

# SSH configuration
$sshKeyName = "linuxboxsshkey"
$sshPublicKeyPath = Join-Path $HOME ".ssh/vm-demo-key.pub"

# Public IP configuration
$publicIpAddressName = "linuxboxpip"
$dnsLabel = "matetask12-aleksandrmajlo-" +
    (Get-Random -Minimum 10000 -Maximum 99999)

# VM configuration
$vmName = "matebox"
$adminUsername = "azureuser"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"

# VM Extension configuration
$extensionName = "install-todo-app"

$installScriptUrl = `
    "https://raw.githubusercontent.com/aleksandrmajlo/azure_task_12_deploy_app_with_vm_extention/azure-majlo/install-app.sh"

# Verify the local public key
if (-not (Test-Path $sshPublicKeyPath)) {
    throw "SSH public key was not found: $sshPublicKeyPath"
}

$sshKeyPublicKey = (Get-Content $sshPublicKeyPath -Raw).Trim()

# Create resource group
Write-Host "Creating resource group $resourceGroupName ..."

New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location

# Create NSG rules
Write-Host "Creating network security group $networkSecurityGroupName ..."

$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
    -Name "SSH" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22 `
    -Access Allow

$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
    -Name "HTTP" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1002 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 8080 `
    -Access Allow

$nsg = New-AzNetworkSecurityGroup `
    -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

# Create VNet and subnet
Write-Host "Creating virtual network $virtualNetworkName ..."

$subnet = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnet

# Create Azure SSH key resource
Write-Host "Creating SSH key resource $sshKeyName ..."

New-AzSshKey `
    -Name $sshKeyName `
    -ResourceGroupName $resourceGroupName `
    -PublicKey $sshKeyPublicKey

# Create Public IP with DNS name
Write-Host "Creating public IP $publicIpAddressName ..."

New-AzPublicIpAddress `
    -Name $publicIpAddressName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Sku "Standard" `
    -AllocationMethod "Static" `
    -DomainNameLabel $dnsLabel

# Create a temporary credential object required by New-AzVM
$securePassword = ConvertTo-SecureString `
    ("Azure!" + [guid]::NewGuid().ToString("N")) `
    -AsPlainText `
    -Force

$credential = [PSCredential]::new(
    $adminUsername,
    $securePassword
)

# Create VM
Write-Host "Creating virtual machine $vmName ..."

New-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName `
    -Location $location `
    -Image $vmImage `
    -Size $vmSize `
    -Credential $credential `
    -VirtualNetworkName $virtualNetworkName `
    -SubnetName $subnetName `
    -SecurityGroupName $networkSecurityGroupName `
    -PublicIpAddressName $publicIpAddressName `
    -SshKeyName $sshKeyName `
    -SecurityType "Standard"

# Configure Custom Script Extension
$extensionSettings = @{
    fileUris = @(
        $installScriptUrl
    )
    commandToExecute = "bash install-app.sh"
}

Write-Host "Installing the application with Custom Script Extension ..."

Set-AzVMExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Location $location `
    -Name $extensionName `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "CustomScript" `
    -TypeHandlerVersion "2.1" `
    -Settings $extensionSettings

# Display application URL
$publicIp = Get-AzPublicIpAddress `
    -ResourceGroupName $resourceGroupName `
    -Name $publicIpAddressName

$applicationUrl = "http://$($publicIp.DnsSettings.Fqdn):8080"

Write-Host ""
Write-Host "Deployment completed."
Write-Host "Application: $applicationUrl"
Write-Host "API: $applicationUrl/api/"