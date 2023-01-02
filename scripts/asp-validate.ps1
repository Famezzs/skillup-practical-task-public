#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $aspName,
    [string] [Parameter(Mandatory=$true)] $aspResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $autoscaleName,
    [string] [Parameter(Mandatory=$true)] $autoscaleResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $deploymentParametersPath
)

function outputValuesDifferError {
    param (
        [string] $parameterName,
        [string] $expectedValue,
        [string] $actualValue
    )
    
    Write-Error "$($parameterName) '$($actualValue)' does not equal $($parameterName) '$($expectedValue)' from parameters file."
}

$aspToValidate = Get-AzResource -Name $aspName `
    -ResourceType 'Microsoft.Web/serverfarms' `
    -ResourceGroupName $aspResourceGroupName

$deploymentParameters = (Get-Content $deploymentParametersPath | ConvertFrom-Json).parameters

if ($aspToValidate.Name -ne $deploymentParameters.aspName.value) {
    outputValuesDifferError -parameterName 'ASP Name' `
        -expectedValue $deploymentParameters.aspName.value `
        -actualValue $aspToValidate.Name
}

if ($aspToValidate.Kind -ne $deploymentParameters.aspKind.value) {
    outputValuesDifferError -parameterName 'ASP Kind' `
        -expectedValue $deploymentParameters.aspKind.value `
        -actualValue $aspToValidate.Kind
}

$aspActualLocation = $aspToValidate.Location.Replace(' ', '')

if ($aspActualLocation -ne $deploymentParameters.aspLocation.value) {
    outputValuesDifferError -parameterName 'ASP Location' `
        -expectedValue $deploymentParameters.aspLocation.value `
        -actualValue $aspActualLocation
}

if ($aspToValidate.Sku.Name -ne $deploymentParameters.aspSkuName.value) {
    outputValuesDifferError -parameterName 'Sku Name' `
        -expectedValue $deploymentParameters.aspSkuName.value `
        -actualValue $aspToValidate.Sku.Name
}

if ($aspToValidate.Sku.Tier -ne $deploymentParameters.aspSkuTier.value) {
    outputValuesDifferError -parameterName 'Sku Tier' `
        -expectedValue $deploymentParameters.aspSkuTier.value `
        -actualValue $aspToValidate.Sku.Tier
}

if ($aspToValidate.Sku.Capacity -ne $deploymentParameters.aspSkuCapacity.value) {
    outputValuesDifferError -parameterName 'Sku Capacity' `
        -expectedValue $deploymentParameters.aspSkuCapacity.value `
        -actualValue $aspToValidate.Sku.Capacity
}

$autoscaleToValidate = (Get-AzResource -Name $autoscaleName `
    -ResourceType 'Microsoft.Insights/autoscalesettings' `
    -ResourceGroupName $autoscaleResourceGroupName).Properties.Profiles

if ($autoscaleToValidate.Capacity.Minimum -ne $deploymentParameters.autoscaleMinimumCapacity.value) {
    outputValuesDifferError -parameterName 'Autoscale Minimum Capacity' `
        -expectedValue $deploymentParameters.autoscaleMinimumCapacity.value `
        -actualValue $autoscaleToValidate.Capacity.Minimum
}

if ($autoscaleToValidate.Capacity.Maximum -ne $deploymentParameters.autoscaleMaximumCapacity.value) {
    outputValuesDifferError -parameterName 'Autoscale Maximum Capacity' `
        -expectedValue $deploymentParameters.autoscaleMaximumCapacity.value `
        -actualValue $autoscaleToValidate.Capacity.Maximum
}

if ($autoscaleToValidate.Capacity.Default -ne $deploymentParameters.autoscaleDefaultCapacity.value) {
    outputValuesDifferError -parameterName 'Autoscale Default Capacity' `
        -expectedValue $deploymentParameters.autoscaleDefaultCapacity.value `
        -actualValue $aspToValidate.Capacity.Default
}