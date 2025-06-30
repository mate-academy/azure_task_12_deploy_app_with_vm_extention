$location = "westeurope"
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

Write-Host "Створення групи ресурсів $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Створення мережевої групи безпеки $networkSecurityGroupName ..."
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow;
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow;
New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH, $nsgRuleHTTP

Write-Host "Створення віртуальної мережі $virtualNetworkName ..."
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnet

Write-Host "Створення SSH ключа $sshKeyName ..."
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

Write-Host "Створення публічної IP адреси $publicIpAddressName ..."
New-AzPublicIpAddress -Name $publicIpAddressName -ResourceGroupName $resourceGroupName -Location $location -Sku Standard -AllocationMethod Static -DomainNameLabel $dnsLabel

Write-Host "Створення віртуальної машини $vmName ..."
New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $vmName `
-Location $location `
-image $vmImage `
-size $vmSize `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName  -PublicIpAddressName $publicIpAddressName

# ↓↓↓ Код для встановлення розширення Custom Script Extension ↓↓↓
Start-Sleep -Seconds 20

Write-Host "Перевірка створення VM..."
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction SilentlyContinue

if ($vm) {
    Write-Host "VM створено успішно. Встановлення Custom Script Extension..."


    $githubUsername = "Alexionx"
    $scriptUri = "https://raw.githubusercontent.com/$githubUsername/azure_task_12_deploy_app_with_vm_extention/main/install-app.sh"

    Set-AzVMExtension `
        -ResourceGroupName $resourceGroupName `
        -VMName $vmName `
        -Name "CustomScript" `
        -Publisher "Microsoft.Azure.Extensions" `
        -ExtensionType "CustomScript" `
        -TypeHandlerVersion "2.1" `
        -Settings @{
            "fileUris" = @($scriptUri)
            "commandToExecute" = "bash install-app.sh"
        } `
        -Location $location

    Write-Host "Отримання інформації про публічну IP адресу..."
    $publicIp = Get-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Name $publicIpAddressName
    $ipAddress = $publicIp.IpAddress
    $dnsName = $publicIp.DnsSettings.Fqdn

    Write-Host "Розгортання завершено!"
    Write-Host "IP адреса: $ipAddress"
    Write-Host "DNS ім'я: $dnsName"
    Write-Host "Веб-додаток буде доступний за адресою: http://$dnsName:8080"
    Write-Host "Або за IP: http://$ipAddress:8080"
    Write-Host "Зачекайте кілька хвилин, поки встановиться додаток, потім перевірте URL у браузері."
} else {
    Write-Host "❌ Помилка: VM не було створено. Перевірте помилки вище."
}