# Azure Virtual Network

Thursday, May 11, 2017
2:40 PM

## Reference

**Create a VNet with a Site-to-Site VPN connection using PowerShell**\
From <[https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-create-site-to-site-rm-powershell](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-create-site-to-site-rm-powershell)>

## # Connect to your subscription

```PowerShell
Login-AzureRmAccount

Get-AzureRmSubscription


Name     : Visual Studio Ultimate with MSDN
Id       : ********-fdf5-4fd0-b21b-{redacted}
TenantId : ********-86e6-4124-a4cb-{redacted}
State    : Enabled

Select-AzureRmSubscription -SubscriptionName "Visual Studio Ultimate with MSDN"
```

## # Create virtual network and gateway subnet

### # Create a resource group

```PowerShell
$azureLocation = "West US"
$resourceGroup = "Network-" + $azureLocation.Replace(" ", "-")

New-AzureRmResourceGroup -Name $resourceGroup -Location $azureLocation
```

### # Create virtual network

```PowerShell
$virtualNetworkName = $azureLocation.Replace(" ", "-") + "-VLAN-71"

$subnet1 = New-AzureRmVirtualNetworkSubnetConfig `
    -Name "GatewaySubnet" `
    -AddressPrefix "10.71.0.0/27"

$subnet2 = New-AzureRmVirtualNetworkSubnetConfig `
    -Name "Management" `
    -AddressPrefix "10.71.1.0/24"

New-AzureRmVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroup `
    -Location $azureLocation `
    -AddressPrefix "10.71.0.0/16" `
    -Subnet $subnet1, $subnet2
```

## # Create the local network gateway

```PowerShell
$localNetworkName = "Technology-Toolbox-Corp"
$localGatewayAddress = "50.246.207.162"
$localSubnets = @(
    "10.1.10.0/24",
    "10.1.11.0/24",
    "10.1.12.0/24",
    "192.168.10.0/24",
    "192.168.11.0/24")

New-AzureRmLocalNetworkGateway `
    -Name $localNetworkName `
    -ResourceGroupName $resourceGroup `
    -Location $azureLocation `
    -GatewayIpAddress $localGatewayAddress `
    -AddressPrefix $localSubnets
```

## # Request Public IP address for VPN gateway

```PowerShell
$virtualNetworkGatewayName = $virtualNetworkName + "-Gateway-1"

$gatewayPublicIPAddress = New-AzureRmPublicIpAddress `
    -Name ($virtualNetworkGatewayName + "-IP") `
    -ResourceGroupName $resourceGroup `
    -Location $azureLocation `
    -AllocationMethod Dynamic
```

## # Create gateway IP addressing configuration

```PowerShell
$vnet = Get-AzureRmVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroup

$subnet = Get-AzureRmVirtualNetworkSubnetConfig `
    -Name 'GatewaySubnet' `
    -VirtualNetwork $vnet

$gatewayIPConfig = New-AzureRmVirtualNetworkGatewayIpConfig `
    -Name ($virtualNetworkGatewayName + "-IP-Config") `
    -SubnetId $subnet.Id `
    -PublicIpAddressId $gatewayPublicIPAddress.Id
```

## # Create VPN gateway

```PowerShell
New-AzureRmVirtualNetworkGateway `
    -Name $virtualNetworkGatewayName `
    -ResourceGroupName $resourceGroup `
    -Location $azureLocation `
    -IpConfigurations $gatewayIPConfig `
    -GatewayType Vpn `
    -VpnType RouteBased `
    -GatewaySku Basic
```

```PowerShell
cls
```

## # Configure local VPN device

```PowerShell
Get-AzureRmPublicIpAddress `
    -Name $gatewayPublicIPAddress.Name `
    -ResourceGroupName $resourceGroup |
    select IPAddress

IpAddress
---------
40.118.255.189
```

```PowerShell
cls
```

## # Create VPN connection

```PowerShell
$virtualNetworkGateway = Get-AzureRmVirtualNetworkGateway `
    -Name $virtualNetworkGatewayName `
    -ResourceGroupName $resourceGroup

$localNetworkGateway = Get-AzureRmLocalNetworkGateway `
    -Name $localNetworkName `
    -ResourceGroupName $resourceGroup
```

### # Create connection

```PowerShell
$connectionName = $localNetworkName + "-1"

New-AzureRmVirtualNetworkGatewayConnection `
    -Name $connectionName `
    -ResourceGroupName $resourceGroup `
    -Location $azureLocation `
    -VirtualNetworkGateway1 $virtualNetworkGateway `
    -LocalNetworkGateway2 $localNetworkGateway `
    -ConnectionType IPsec `
    -RoutingWeight 10 `
    -SharedKey {shared key}
```

## # Verify the VPN connection

```PowerShell
Get-AzureRmVirtualNetworkGatewayConnection `
    -Name "Technology-Toolbox" `
    -ResourceGroupName $resourceGroup |
    select ConnectionStatus, EgressBytesTransferred, IngressBytesTransferred
```
