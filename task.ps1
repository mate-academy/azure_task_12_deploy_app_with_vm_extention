# ==================== VARIABLES ====================
$location = "uaenorth"

$resourceGroupName = "mate-azure-task-12"
$vnetName = "vnet"
$subnetName = "default"
$nsgName = "defaultnsg"

$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

$vmName = "matebox"
$vmSize = "Standard_D2s_v3"

$publicIpName = "linuxboxpip"

$publisher = "Canonical"
$offer = "0001-com-ubuntu-server-jammy"
$sku = "22_04-lts"
$version = "latest"

$dnsLabel = "matebox" + (Get-Random -Minimum 1000 -Maximum 9999)

# ==================== RESOURCE GROUP ====================
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# ==================== NSG ====================
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
    -Name "SSH" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 22 -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
    -Name "HTTP" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1002 `
    -SourceAddressPrefix "*" `
    -SourcePortRange "*" `
    -DestinationAddressPrefix "*" `
    -DestinationPortRange 8080 -Access Allow
$nsg = New-AzNetworkSecurityGroup `
    -Name $nsgName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $nsgRuleSSH, $nsgRuleHTTP `
    -Force

# ==================== VNET ====================
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix `
    -NetworkSecurityGroup $nsg

$vnet = New-AzVirtualNetwork `
    -Name $vnetName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnetConfig `
    -Force

# ==================== SSH KEY (REQUIRED FOR VALIDATOR) ====================
$sshKeyName = "linuxboxsshkey"

$sshKey = New-AzSshKey `
    -ResourceGroupName $resourceGroupName `
    -Name $sshKeyName `
    -PublicKey (Get-Content "$HOME\.ssh\id_rsa.pub")

# ==================== PUBLIC IP ====================
$publicIp = New-AzPublicIpAddress `
    -Name $publicIpName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AllocationMethod Static `
    -Sku Standard `
    -DomainNameLabel $dnsLabel `
    -Force

# ==================== NIC ====================
$nic = New-AzNetworkInterface `
    -Name "$vmName-nic" `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $publicIp.Id

# ==================== VM CONFIG ====================
$cred = Get-Credential -UserName "funcVM"

$vmConfig = New-AzVMConfig `
    -VMName $vmName `
    -VMSize $vmSize

$vmConfig = Set-AzVMOperatingSystem `
    -VM $vmConfig `
    -Linux `
    -ComputerName $vmName `
    -Credential $cred `
    -DisablePasswordAuthentication:$false

$vmConfig = Set-AzVMSourceImage `
    -VM $vmConfig `
    -PublisherName $publisher `
    -Offer $offer `
    -Skus $sku `
    -Version $version

# ==================== NETWORK PROFILE (CRITICAL FIX) ====================
$vmConfig = Add-AzVMNetworkInterface `
    -VM $vmConfig `
    -Id $nic.Id `
    -Primary

# ==================== CREATE VM ====================
New-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -VM $vmConfig `
    -SshKeyName $sshKeyName

# ==================== EXTENSION ====================
$scriptUri = "https://raw.githubusercontent.com/Xandane/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh"

Set-AzVMExtension `
    -ResourceGroupName $resourceGroupName `
    -VMName $vmName `
    -Location $location `
    -Name "deployApp" `
    -Publisher "Microsoft.Azure.Extensions" `
    -ExtensionType "CustomScript" `
    -TypeHandlerVersion "2.1" `
    -Settings @{
        fileUris = @($scriptUri)
        commandToExecute = "bash install-app.sh"
    }

Write-Host "DONE"