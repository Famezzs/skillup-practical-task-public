#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $webappName,
    [string] [Parameter(Mandatory=$true)] $webappResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $deploymentParametersPath
)

$totalErrorCount = 0

function outputValuesDifferError {
    param (
        [string] $parameterName,
        [string] $expectedValue,
        [string] $actualValue
    )
    
    $Script:totalErrorCount++

    Write-Error "$parameterName '$actualValue' does not equal $parameterName '$expectedValue' from parameters file."
}

$webappToValidate = Set-AzWebApp -Name $webappName -ResourceGroupName $webappResourceGroupName

if ($null -eq $webappToValidate) {
    Write-Error 'WebApp specified could not be found.'
    exit 1
}

$deploymentParameters = (Get-Content $deploymentParametersPath | ConvertFrom-Json).parameters

if ($webappToValidate.Name -ne $deploymentParameters.webappName.value) {
    outputValuesDifferError -parameterName 'WebApp Name' `
        -expectedValue $deploymentParameters.aspName.value `
        -actualValue $aspToValidate.Name
    
}

$webappActualLocation = $webappToValidate.Location.Replace(' ', '')

if ($webappActualLocation -ne $deploymentParameters.webappLocation.value) {
    outputValuesDifferError -parameterName 'WebApp Location' `
        -expectedValue $deploymentParameters.aspLocation.value `
        -actualValue $aspActualLocation
}

$aspResourceId = (Get-AzResource -Name $deploymentParameters.aspName.value `
    -ResourceType 'Microsoft.Web/serverfarms' `
    -ResourceGroupName $deploymentParameters.aspResourceGroupName.value).ResourceId

if ($webappToValidate.ServerFarmId -ne $aspResourceId) {
    outputValuesDifferError -parameterName 'WebApp Associate ASP' `
        -expectedValue $aspResourceId `
        -actualValue $webappToValidate.ServerFarmId
}

$webappCurrentStack = $webappToValidate.SiteConfig.MetaData.Where({($_.Name -eq 'CURRENT_STACK')}, 'First')

if ($webappCurrentStack.value -ne $deploymentParameters.webappCurrentStack.value) {
    outputValuesDifferError -parameterName 'WebApp Current Stack' `
        -expectedValue $deploymentParameters.webappCurrentStack.value `
        -actualValue $webappCurrentStack.value
}

if ($webappToValidate.SiteConfig.ManagedPipelineMode -ne $deploymentParameters.webappManagedPipelineMode.value) {
    outputValuesDifferError -parameterName 'WebApp Managed Pipeline Mode' `
        -expectedValue $deploymentParameters.webappManagedPipelineMode.value `
        -actualValue $webappToValidate.SiteConfig.ManagedPipelineMode
}

if ($totalErrorCount -eq 0) {
    Write-Output 'Successfully validated the resource. No errors encountered.'
    exit 0
} else {
    Write-Output "There were errors encountered during the validation process. Total error count: $totalErrorCount."
    exit 1
}
