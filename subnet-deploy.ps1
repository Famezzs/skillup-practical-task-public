#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $vnetName,
    [string] [Parameter(Mandatory=$true)] $vnetResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $subnetName,
    [string] [Parameter(Mandatory=$true)] $subnetAddressPrefix,
    [string] $nsgName,
    [string] $nsgResourceGroupName,
    [string] $delegationServiceName
)

$vnetSpecified = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetResourceGroupName

if ( $null -eq $vnetSpecified )
{
    Write-Error "Could not find vnet '$vnetName' in resource group '$vnetResourceGroupName'."
    exit 1
}

if ( $nsgName ) 
{
    $nsgSpecified = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $nsgResourceGroupName

    if ( $null -eq $nsgSpecified )
    {
        Write-Error "Could not find nsg '$nsgName' in resource group '$nsgResourceGroupName'."
        exit 1
    }
}

if ( $delegationServiceName )
{
    $delegationSpecified = New-AzDelegation -Name "serverFarmsDelegation" -ServiceName "Microsoft.Web/serverfarms"
}

Add-AzVirtualNetworkSubnetConfig -Name $subnetName `
    -VirtualNetwork $vnetSpecified `
    -AddressPrefix $subnetAddressPrefix `
    -Delegation $delegationSpecified `
    -NetworkSecurityGroup $nsgSpecified `
    | Set-AzVirtualNetwork