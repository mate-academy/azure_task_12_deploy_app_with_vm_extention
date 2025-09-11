# ---------------------------
# Variables
# ---------------------------
$location              = "uksouth"
$resourceGroupName     = "mate-azure-task-12"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName    = "vnet"
$subnetName            = "default"
$vnetAddressPrefix     = "10.0.0.0/16"
$subnetAddressPrefix   = "10.0.0.0/24"
$sshKeyName            = "linuxboxsshkey"
$sshKeyPath            = "~/.ssh/id_rsa.pub"
$publicIpAddressPrefix = "linuxboxpip"
$vmBaseName            = "matebox"
$vmImage               = "Ubuntu2204"
$vmSize                = "Standard_B1s"
$githubUsername        = "LitvinchukRoman"   # змінюй на свій GitHub
$vmCount               = 1                   # контрольна змінна для кількох VM
$dnsLabelPrefix        = "matetask"

# ---------------------------
# Checks
# ---------------------------
if (-not (Test-Path $sshKeyPath)) {
    throw "SSH public key not found at $sshKeyPath"
}
$sshKeyPublicKey = Get-Content $sshKeyPath

# ---------------------------
# Resource Group
# ---------------------------
Write-Host "Creating resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

# ---------------------------
# Networking
# ---------------------------
Write-Host "Creating NSG $networkSecurityGroupName ..."
$nsgRuleSSH  = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22   -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

# ---------------------------
# VM Deployment (multi-VM loop)
# ---------------------------
for ($i = 1; $i -le $vmCount; $i++) {
    $vmName   = "$vmBaseName$i"
    $pipName  = "$publicIpAddressPrefix$i"
    $dnsLabel = "$dnsLabelPrefix$((Get-Random))"

    Write-Host "Creating Public IP $pipName ..."
    New-AzPublicIpAddress -Name $pipName -ResourceGroupName $resourceGroupName -Location $location -Sku Standard -AllocationMethod Static -DomainNameLabel $dnsLabel

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
        -PublicIpAddressName $pipName

    # ---------------------------
    # VM Extension
    # ---------------------------
    $Params = @{
        ResourceGroupName  = $resourceGroupName
        VMName             = $vmName
        Name               = 'CustomScript'
        Publisher          = 'Microsoft.Azure.Extensions'
        ExtensionType      = 'CustomScript'
        TypeHandlerVersion = '2.1'
        Settings           = @{
            fileUris = @("https://raw.githubusercontent.com/$githubUsername/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh")
        }
        ProtectedSettings  = @{
            commandToExecute = 'bash install-app.sh'
        }
    }

    Write-Host "Applying Custom Script Extension to $vmName ..."
    Set-AzVMExtension @Params
}