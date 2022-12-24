#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $nsgName,
    [string] [Parameter(Mandatory=$true)] $resourceGroupName,
    [string] [Parameter(Mandatory=$true)] $location
)

$allowHttpsInbound = New-AzNetworkSecurityRuleConfig -Name AllowHttpsInbound -Description "Allow HTTPS" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443

$allowAllOutbound = New-AzNetworkSecurityRuleConfig -Name AllowInternetOutbound -Description "Allow all outbound" `
    -Access Allow -Protocol * -Direction Outbound -Priority 200 -SourceAddressPrefix `
    * -SourcePortRange * -DestinationAddressPrefix Internet -DestinationPortRange *

New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName  -Location  $location `
    -SecurityRules $allowHttpsInbound,$allowAllOutbound

