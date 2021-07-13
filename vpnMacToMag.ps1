#region Declare variables
# MAC variables
$macVNetName  = "vnet-vpn-test"
$macRG = "rg-vpn-test"
$macLocation = "East US"
$macGWSubName = "GatewaySubnet"
$macVNetPrefix1 = "10.2.0.0/16"
$macGWSubPrefix = "10.2.255.0/27"
$macGWName = "gw-vpn-test"
$macGWIPName = "pip-vpngw-test"
$macGWIPconfName = "config-vpngw-test"
$macLNGName = "MAG"
$macConnectionName = "MAC-to-MAG"

# MAG variables
$magVNetName  = "vnet-vpn-test"
$magRG = "rg-vpn-test"
$magLocation = "usdodeast"
$magGWSubName = "GatewaySubnet"
$magVNetPrefix1 = "10.1.0.0/16"
$magGWSubPrefix = "10.1.255.0/27"
$magGWName = "gw-vpn-tes"
$magGWIPName = "pip-vpngw-test"
$magGWIPconfName = "config-vpngw-test"
$magLNGName = "MAC"
$magConnectionName = "MAC-to-MAG"
#endregion

#region Execute in MAC
#
# Login to MAC
Connect-AzAccount

# Create a resource group
New-AzResourceGroup -Name $macRG `
                    -Location $macLocation

$virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $macRG `
                    -Location $macLocation `
                    -Name $macVNetName `
                    -AddressPrefix $macVNetPrefix1

# Set the subnet configuration for the virtual network
$virtualNetwork | Set-AzVirtualNetwork

# Add a gateway subnet
$macVnet = Get-AzVirtualNetwork -ResourceGroupName $macRG `
          -Name $macVNetName

Add-AzVirtualNetworkSubnetConfig -Name $macGWSubName `
              -AddressPrefix $macGWSubPrefix `
              -VirtualNetwork $macVnet

# Set the subnet configuration for the virtual network
$macVnet | Set-AzVirtualNetwork

# Request a public IP address
$macGwpip = New-AzPublicIpAddress -Name $macGWIPName `
            -ResourceGroupName $macRG `
            -Location $macLocation `
            -AllocationMethod Dynamic

$macSubnet = Get-AzVirtualNetworkSubnetConfig -Name $macGWSubName `
                        -VirtualNetwork $macVnet

$macGwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name $macGWIPconfName `
                               -SubnetId $macSubnet.Id `
                               -PublicIpAddressId $macGwpip.Id

# Create the VPN gateway
New-AzVirtualNetworkGateway -Name $macGWName `
                            -ResourceGroupName $macRG `
                            -Location $macLocation `
                            -IpConfigurations $macGwipconfig `
                            -GatewayType Vpn `
                            -VpnType RouteBased `
                            -GatewaySku VpnGw1

#endregion

#region Execute in MAG
# Login to MAG
Connect-AzAccount -EnvironmentName AzureUSGovernment

# Create a resource group
New-AzResourceGroup -Name $magRG `
                    -Location $magLocation

$virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $magRG `
                                       -Location $magLocation `
                                       -Name $magVNetName `
                                       -AddressPrefix $magVNetPrefix1

# Set the subnet configuration for the virtual network
$virtualNetwork | Set-AzVirtualNetwork

# Add a gateway subnet
$magVnet = Get-AzVirtualNetwork -ResourceGroupName $magRG `
                             -Name $magVNetName

Add-AzVirtualNetworkSubnetConfig -Name $magGWSubName `
                                 -AddressPrefix $magGWSubPrefix `
                                 -VirtualNetwork $magvnet

# Set the subnet configuration for the virtual network
$magvnet | Set-AzVirtualNetwork

# Request a public IP address
$maggwpip = New-AzPublicIpAddress -Name $magGWIPName `
            -ResourceGroupName $magRG `
            -Location $magLocation `
            -AllocationMethod Dynamic

# Create the gateway IP address configuration
$magvnet = Get-AzVirtualNetwork -Name $magVNetName `
          -ResourceGroupName $magRG

$magsubnet = Get-AzVirtualNetworkSubnetConfig -Name $magGWSubName `
                        -VirtualNetwork $magVnet

$magGwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name $magGWIPconfName `
                               -SubnetId $magSubnet.Id `
                               -PublicIpAddressId $magGwpip.Id

# Create the VPN gateway
New-AzVirtualNetworkGateway -Name $magGWName `
                            -ResourceGroupName $magRG `
                            -Location $magLocation `
                            -IpConfigurations $magGwipconfig `
                            -GatewayType Vpn `
                            -VpnType RouteBased `
                            -GatewaySku VpnGw1

#endregion

#region Execute in MAC
Connect-AzAccount

$macPip = (Get-AzPublicIpAddress -Name $macGWIPName).IpAddress

New-AzLocalNetworkGateway -Name $macLNGName `
                          -ResourceGroupName $macRG `
                          -Location $macLocation `
                          -GatewayIpAddress $macPip `
                          -AddressPrefix @($macVNetPrefix1)
# Configure your on-premises VPN device
# Create the VPN connection
$macGateway = Get-AzVirtualNetworkGateway -Name $macGWName `
                                        -ResourceGroupName $macRG
$macLocal = Get-AzLocalNetworkGateway -Name $macLNGName `
                                   -ResourceGroupName $macRG
New-AzVirtualNetworkGatewayConnection -Name $macConnectionName `
                                      -ResourceGroupName $macRG `
                                      -Location $macLocation `
                                      -VirtualNetworkGateway1 $macgateway `
                                      -LocalNetworkGateway2 $maclocal `
                                      -ConnectionType IPsec `
                                      -ConnectionProtocol IKEv2 `
                                      -RoutingWeight 10 `
                                      -SharedKey 'abc123'
#endregion

#region Execute in MAG
# LNG in MAG
Connect-AzAccount -EnvironmentName AzureUSGovernment

$magPip = (Get-AzPublicIpAddress -Name $magGWIPName).IpAddress

New-AzLocalNetworkGateway -Name $magLNGName `
                          -ResourceGroupName $magRG `
                          -Location $magLocation `
                          -GatewayIpAddress $magPip `
                          -AddressPrefix @($magVNetPrefix1)
# Configure your on-premises VPN device
# Create the VPN connection
$magGateway = Get-AzVirtualNetworkGateway -Name $magGWName `
                                        -ResourceGroupName $magRG
                                        
$magLocal = Get-AzLocalNetworkGateway -Name $magLNGName `
                                   -ResourceGroupName $magRG

New-AzVirtualNetworkGatewayConnection -Name $magConnectionName `
                                      -ResourceGroupName $magRG `
                                      -Location $magLocation `
                                      -VirtualNetworkGateway1 $magGateway `
                                      -LocalNetworkGateway2 $magLocal `
                                      -ConnectionType IPsec `
                                      -ConnectionProtocol IKEv2 `
                                      -RoutingWeight 10 `
                                      -SharedKey 'abc123'
#endregion