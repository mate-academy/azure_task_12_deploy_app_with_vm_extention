$location = "polandcentral"
$resourceGroupName = "mate-azure-task-12"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = (Get-Content -Raw "/root/.ssh/mate_azure_vm.pub").Trim() 
$publicIpAddressName = "linuxboxpip"
$vmName = "matebox"
$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
$sshKeyPublicKey = (Get-Content -Raw "/root/.ssh/mate_azure_vm.pub").Trim()
$dnsLabel = ("matetask{0}" -f (Get-Random -Minimum 10000 -Maximum 99999)).ToLower()
$adminUsername = "azureuser"
$plainPassword = "P@ss" + (Get-Random -Minimum 10000000 -Maximum 99999999) + "aA!"
$adminPassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

New-AzPublicIpAddress `
  -Name $publicIpAddressName `
  -ResourceGroupName $resourceGroupName `
  -Location $location `
  -Sku Standard `
  -AllocationMethod Static `
  -IpAddressVersion IPv4 `
  -DomainNameLabel $dnsLabel

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
  -Credential $cred

# ↓↓↓ Write your code here ↓↓↓

# ===== VM Extension: Custom Script =====
$extName = "install-todo-app"
$publisher = "Microsoft.Azure.Extensions"
$extType = "CustomScript"
$handlerVersion = "2.1"

# 1) Динамически вытаскиваем username и repo из remote.origin.url
$originUrl = (git config --get remote.origin.url).Trim()

if ($originUrl -match "github\.com[:/](?<user>[^/]+)/(?<repo>[^/.]+)(\.git)?$") {
  $githubUser = $Matches.user
  $repoName = $Matches.repo
} else {
  throw "Cannot parse GitHub username/repo from origin url: $originUrl"
}

# 2) Требование задачи: ссылка ДОЛЖНА указывать на ветку main
$installScriptUrl = "https://raw.githubusercontent.com/$githubUser/$repoName/main/install-app.sh"

# 3) Удалим extension, если была (чтобы не мешали старые попытки)
Remove-AzVMExtension `
  -ResourceGroupName $resourceGroupName `
  -VMName $vmName `
  -Name $extName `
  -Force `
  -ErrorAction SilentlyContinue | Out-Null

# 4) Для CustomScript: fileUris -> Settings, commandToExecute -> ProtectedSettings
$settings = @{
  fileUris = @($installScriptUrl)
}

$protectedSettings = @{
  commandToExecute = "bash install-app.sh"
}

Write-Host "Installing VM extension (Custom Script) to deploy app..."
Set-AzVMExtension `
  -ResourceGroupName $resourceGroupName `
  -VMName $vmName `
  -Name $extName `
  -Publisher $publisher `
  -ExtensionType $extType `
  -TypeHandlerVersion $handlerVersion `
  -Location $location `
  -Settings $settings `
  -ProtectedSettings $protectedSettings `
  -ForceRerun ([Guid]::NewGuid().ToString()) `
  -Verbose | Out-Null

Write-Host "Extension deployed. App should be available soon on: http://$dnsLabel.$location.cloudapp.azure.com:8080"

