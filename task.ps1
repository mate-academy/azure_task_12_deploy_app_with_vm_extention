$linuxUser = "azur11"
$linuxPassword = "YourSecurePassword123!" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($linuxUser, $linuxPassword)
$location = "uksouth"
$resourceGroupName = "mate-azure-task-12"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$publicIpAddressName = "linuxboxpip"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
do {
    $randomSuffix = Get-Random -Minimum 100 -Maximum 999
    $dnsLabel = "matetask$randomSuffix"
    $dnsAvailable = (Test-AzDnsAvailability -DomainNameLabel $dnsLabel -Location $location)
} until ($dnsAvailable)
$keyPath = "$HOME\.ssh\$linuxUser"

if (-not (Test-Path "$HOME\.ssh\$linuxUser.pub")) {
    Write-Host "SSh key not found. Generating SSH key..." -ForegroundColor Cyan
    ssh-keygen -t rsa -b 4096 -f $keyPath -N "" | Out-Null
}

$sshKeyPublicKey = (Get-Content "$HOME\.ssh\$linuxUser.pub" -Raw).Trim()

Write-Host "Creating a resource group $resourceGroupName ..." -ForegroundColor Cyan
New-AzResourceGroup -Name $resourceGroupName -Location $location | Out-Null

Write-Host "Creating a network security group $networkSecurityGroupName ..." -ForegroundColor Cyan
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet | Out-Null
Write-Host "Uploading SSH key..." -ForegroundColor Cyan
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey | Out-Null
Write-Host "Creating public IP address with DNS name..." -ForegroundColor Cyan
New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Basic -AllocationMethod Dynamic -DomainNameLabel $dnsLabel | Out-Null
Write-Host "Creating virtual machine..." -ForegroundColor Cyan
New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $vmName `
-Location $location `
-image $vmImage `
-credential $credential `
-size $vmSize `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-PublicIpAddressName $publicIpAddressName

Write-Host "Adding custom script extension..." -ForegroundColor Cyan
$Params = @{
    ResourceGroupName  = $resourceGroupName
    VMName             = $vmName
    Name               = 'CustomScript'
    Publisher          = 'Microsoft.Azure.Extensions'
    ExtensionType      = 'CustomScript'
    TypeHandlerVersion = '2.1'
    Settings          = @{fileUris = @("https://raw.githubusercontent.com/trinidaa/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh")
        commandToExecute = "./install-app.sh"}
}
Set-AzVMExtension @Params