# Налаштування групи ресурсів та віртуальної машини
$resourceGroupName = "mateAzureTask12"
$location = "westeurope"
$vmName = "mateWebAppVM"
$publicIpDnsName = "matewebappvm" + (Get-Random -Minimum 1000 -Maximum 9999)

# 1. Створення групи ресурсів
New-AzResourceGroup -Name $resourceGroupName -Location $location

# 2. Налаштування підмережі
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name "mySubnet" -AddressPrefix 192.168.1.0/24

# 3. Створення віртуальної мережі
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location `
  -Name "myVNET" -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig

# 4. Створення публічної IP-адреси
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location `
  -Name "myPublicIP" -AllocationMethod Dynamic -DomainNameLabel $publicIpDnsName

# 5. Налаштування групи безпеки мережі (відкриваємо порт 8080)
$nsgRule = New-AzNetworkSecurityRuleConfig -Name "myNetworkSecurityGroupRuleWeb" -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 8080 -Access Allow

$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location `
  -Name "myNetworkSecurityGroup" -SecurityRules $nsgRule

# 6. Налаштування IP-конфігурації
$ipConfig = New-AzNetworkInterfaceIpConfig -Name "myIpConfig" -Subnet $vnet.Subnets[0] `
  -PublicIpAddress $pip -PrivateIpAddressVersion IPv4

# 7. Створення мережевого інтерфейсу
$nic = New-AzNetworkInterface -Name "myNic" -ResourceGroupName $resourceGroupName `
  -Location $location -IpConfiguration $ipConfig -NetworkSecurityGroup $nsg

# 8. Налаштування облікових даних для Linux (логін: azureuser, пароль: Azure123456!)
$securePassword = ConvertTo-SecureString "Azure123456!" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

# 9. Налаштування конфігурації віртуальної машини (Ubuntu 18.04 LTS)
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_B1s" | `
  Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential $cred | `
  Set-AzVMSourceImage -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "18.04-LTS" -Version "latest" | `
  Add-AzVMNetworkInterface -Id $nic.Id

# 10. Створення віртуальної машини
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

# 11. Встановлення веб-додатку через Custom Script Extension
Set-AzVMExtension -ResourceGroupName $resourceGroupName -VMName $vmName -Name "webAppDeployment" `
  -Publisher "Microsoft.Azure.Extensions" -ExtensionType "CustomScript" -TypeHandlerVersion "2.0" `
  -SettingString '{
    "fileUris": ["https://raw.githubusercontent.com/Yevgene-DP/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh"],
    "commandToExecute": "bash install-app.sh"
  }'

# 12. Отримання публічної IP-адреси
$ip = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name "myPublicIP"

Write-Output "Додаток успішно розгорнуто!"
Write-Output "Доступ до додатку: http://$($ip.DnsSettings.Fqdn):8080"