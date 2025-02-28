# Задаємо змінні
$resourceGroupName = "mate-resources"
$location = "uksouth"
$storageAccountName = "matestorage123" # Має бути унікальним у всій Azure
$skuName = "Standard_LRS"

# Створюємо ресурсну групу (якщо її ще немає)
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Створюємо Storage Account
New-AzStorageAccount -ResourceGroupName $resourceGroupName `
                     -Name $storageAccountName `
                     -Location $location `
                     -SkuName $skuName `
                     -Kind StorageV2

# Створюємо контейнер у Storage Account
$storageContext = (Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context
New-AzStorageContainer -Name "task-artifacts" -Context $storageContext -Permission Off
