#Let's Connect to Azure from Local Machine skip this part if you are accessing through browser and go to variable creations. 
Add-AzureRmAccount

#Provide some variables
$resourceGroup = "WEU-Assets"
$location = "West Europe"
$vmName = "WEU-VM01"

#Define User Credentials
$cred = Get-Credential -Message "Please Provide the Credentials"

#The Resource Group
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

#Subnet configuration will be added to a variable
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name SN01 -AddressPrefix 10.205.1.0/24

#Vnet Definition
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location -Name WEU-VNet01 -AddressPrefix 10.205.0.0/16 -Subnet $subnetConfig

#Public IP and DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location -Name "WEU-VM01-Pip01$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

#Inbound security rules for the NSG assigned to this VM
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name WEU-NSGRuleRDP -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

#NSG Settings
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location -Name WEU-NSG01 -SecurityRules $nsgRuleRDP

#Assign the vNic, NSG, & Virtual IP
$nic = New-AzureRmNetworkInterface -Name WEU-VM01Nic01 -ResourceGroupName $resourceGroup -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

#Time to Create the VM Config variable the collected information 
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_DS1_v2 | Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2019-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id

#Time to Build the VM
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig