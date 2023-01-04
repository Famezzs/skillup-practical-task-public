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

if ($webappToValidate.SiteConfig.ManagedPipelineMode -ne $deploymentParameters.webappManagedPipelineMode.value) {
    outputValuesDifferError -parameterName 'WebApp Managed Pipeline Mode' `
        -expectedValue $deploymentParameters.webappManagedPipelineMode.value `
        -actualValue $webappToValidate.SiteConfig.ManagedPipelineMode
}

if ($webappToValidate.SiteConfig.FtpsState -ne $deploymentParameters.webappFtpsState.value) {
    outputValuesDifferError -parameterName 'WebApp Ftps State' `
        -expectedValue $deploymentParameters.webappFtpsState.value `
        -actualValue $webappToValidate.SiteConfig.FtpsState
}

if ($webappToValidate.SiteConfig.WebSocketsEnabled -ne $deploymentParameters.webappWebSocketsEnabled.value) {
    outputValuesDifferError -parameterName 'WebApp Web Sockets Enabled' `
        -expectedValue $deploymentParameters.webappWebSocketsEnabled.value `
        -actualValue $webappToValidate.SiteConfig.WebSocketsEnabled
}

if ($webappToValidate.SiteConfig.AlwaysOn -ne $deploymentParameters.webappAlwaysOn.value) {
    outputValuesDifferError -parameterName 'WebApp Always On' `
        -expectedValue $deploymentParameters.webappAlwaysOn.value `
        -actualValue $webappToValidate.SiteConfig.AlwaysOn
}

if ($webappToValidate.SiteConfig.RemoteDebuggingEnabled -ne $deploymentParameters.webappRemoteDebuggingEnabled.value) {
    outputValuesDifferError -parameterName 'WebApp Remote Debugging Enabled' `
        -expectedValue $deploymentParameters.webappRemoteDebuggingEnabled.value `
        -actualValue $webappToValidate.SiteConfig.RemoteDebuggingEnabled
}

if ($webappToValidate.SiteConfig.MinTlsVersion -ne $deploymentParameters.webappMinimumTLSVersion.value) {
    outputValuesDifferError -parameterName 'WebApp Minimum Tls Version' `
        -expectedValue $deploymentParameters.webappMinimumTLSVersion.value `
        -actualValue $webappToValidate.SiteConfig.MinTlsVersion
}

if ($webappToValidate.ClientAffinityEnabled -ne $deploymentParameters.webappClientAffinityEnabled.value) {
    outputValuesDifferError -parameterName 'WebApp Client Affinity Enabled' `
        -expectedValue $deploymentParameters.webappClientAffinityEnabled.value `
        -actualValue $webappToValidate.ClientAffinityEnabled    
}

if ($webappToValidate.ClientCertEnabled -ne $deploymentParameters.webappClientCertificateEnabled.value) {
    outputValuesDifferError -parameterName 'WebApp Client Certificate Enabled' `
        -expectedValue $deploymentParameters.webappClientCertificateEnabled.value `
        -actualValue $webappToValidate.ClientCertEnabled
}

if ($webappToValidate.ClientCertEnabled) {
    if ($webappToValidate.ClientCertMode -ne $deploymentParameters.webappClientCertificateMode.value) {
        outputValuesDifferError -parameterName 'WebApp Client Certificate Mode' `
            -expectedValue $deploymentParameters.webappClientCertificateMode.value `
            -actualValue $webappToValidate.ClientCertMode
    }
}

if ($webappToValidate.HttpsOnly -ne $deploymentParameters.webappHttpsOnly.value) {
    outputValuesDifferError -parameterName 'WebApp Https Only' `
        -expectedValue $deploymentParameters.webappHttpsOnly.value `
        -actualValue $webappToValidate.HttpsOnly
}

if ($webappToValidate.SiteConfig.VnetRouteAllEnabled -ne $deploymentParameters.webappVnetRouteAll.value) {
    outputValuesDifferError -parameterName 'WebApp Vnet Route All' `
        -expectedValue $deploymentParameters.webappVnetRouteAll.value `
        -actualValue $webappToValidate.SiteConfig.VnetRouteAllEnabled
}


if ($webappToValidate.SiteConfig.IpSecurityRestrictions.Count -ne 0 -and $deploymentParameters.webappIpRestrictions.value.Count -ne 0) {

    $webappIpRestrictionsAreValid = $true

    if ($webappToValidate.SiteConfig.IpSecurityRestrictions.Count -ne $deploymentParameters.webappIpRestrictions.value.Count) {
        $webappIpRestrictionsAreValid = $false
    }

    for ($index = 0; $index -lt $deploymentParameters.webappIpRestrictions.value.Count -and $webappIpRestrictionsAreValid; $index++) {
        $webappIpRestrictionsAreValid = $webappToValidate.SiteConfig.IpSecurityRestrictions -contains $deploymentParameters.webappIpRestrictions[$index]
    }

    if (-not $webappIpRestrictionsAreValid) {
        outputValuesDifferError -parameterName 'WebApp Ip Restrictions' `
            -expectedValue $deploymentParameters.webappIpRestrictions.value `
            -actualValue $webappToValidate.SiteConfig.IpSecurityRestrictions
    }
}

$expectedNetFrameworkVersion = $deploymentParameters.webappNetFrameworkVersion.value -replace 'v',''
$actualNetFrameworkVersion = $webappToValidate.SiteConfig.NetFrameworkVersion -replace 'v',''

if ($actualNetFrameworkVersion -ne $expectedNetFrameworkVersion) {
    outputValuesDifferError -parameterName 'WebApp Net Framework Version' `
        -expectedValue $expectedNetFrameworkVersion `
        -actualValue $actualNetFrameworkVersion
}

if ($webappToValidate.SiteConfig.JavaVersion -or $deploymentParameters.webappJavaVersion.value) {
    if ($webappToValidate.SiteConfig.JavaVersion -ne $deploymentParameters.webappJavaVersion.value) {
        outputValuesDifferError -parameterName 'WebApp Java Version' `
            -expectedValue $deploymentParameters.webappJavaVersion.value `
            -actualValue $webappToValidate.SiteConfig.JavaVersion
    }
}

if ($webappToValidate.SiteConfig.LinuxFxVersion -ne $deploymentParameters.webappLinuxFrameworkVersion.value) {
    outputValuesDifferError -parameterName 'WebApp Linux Framework Version' `
        -expectedValue $deploymentParameters.webappLinuxFrameworkVersion.value `
        -actualValue $webappToValidate.SiteConfig.LinuxFxVersion
}

if ($webappToValidate.SiteConfig.NodeVersion -ne $deploymentParameters.webappNodeVersion.value) {
    outputValuesDifferError -parameterName 'WebApp Node Version' `
        -expectedValue $deploymentParameters.webappNodeVersion.value `
        -actualValue $webappToValidate.SiteConfig.NodeVersion
}

if ($webappToValidate.SiteConfig.PhpVersion -ne $deploymentParameters.webappPhpVersion.value) {
    outputValuesDifferError -parameterName 'WebApp Php Version' `
        -expectedValue $deploymentParameters.webappPhpVersion.value `
        -actualValue $webappToValidate.SiteConfig.PhpVersion
}

if ($webappToValidate.SiteConfig.PythonVersion -ne $deploymentParameters.webappPythonVersion.value) {
    outputValuesDifferError -parameterName 'WebApp Python Version' `
        -expectedValue $deploymentParameters.webappPythonVersion.value `
        -actualValue $webappToValidate.SiteConfig.PythonVersion
}

if ($webappToValidate.SiteConfig.Http20Enabled -ne $deploymentParameters.webappHttp20Enabled.value) {
    outputValuesDifferError -parameterName 'WebApp Http 2.0 Enabled' `
        -expectedValue $deploymentParameters.webappHttp20Enabled.value `
        -actualValue $webappToValidate.SiteConfig.Http20Enabled
}

$actualAppInsightsKey = $webappToValidate.SiteConfig.AppSettings.Where({$_.Name -eq 'APPINSIGHTS_INSTRUMENTATIONKEY'},'First')
$actualAppInsightsConnectionString = $webappToValidate.SiteConfig.AppSettings.Where({$_.Name -eq 'APPLICATIONINSIGHTS_CONNECTION_STRING'},'First')

if ($deploymentParameters.appInsightsName.value) {
    $webappExpectedAppInsights = Get-AzApplicationInsights -Name $deploymentParameters.appInsightsName.value `
        -ResourceGroupName $webappToValidate.ResourceGroup

    if ($actualAppInsightsKey.Value -ne $webappExpectedAppInsights.InstrumentationKey) {
        outputValuesDifferError -parameterName 'WebApp App Insights Instrumentation Key' `
            -expectedValue $webappExpectedAppInsights.InstrumentationKey `
            -actualValue $actualAppInsightsKey
    }

    if ($actualAppInsightsConnectionString.Value -ne $webappExpectedAppInsights.ConnectionString) {
        outputValuesDifferError -parameterName 'WebApp App Insights Connection String' `
            -expectedValue $webappExpectedAppInsights.ConnectionString `
            -actualValue $actualAppInsightsConnectionString
    }
} else {
    if ($actualAppInsightsKey.Value) {
        outputValuesDifferError -parameterName 'WebApp App Insights Instrumentation Key' `
            -expectedValue $null `
            -actualValue $actualAppInsightsKey.Value
    }

    if ($actualAppInsightsConnectionString.Value) {
        outputValuesDifferError -parameterName 'WebApp App Insights Connection String' `
            -expectedValue $null `
            -actualValue $actualAppInsightsConnectionString.Value
    }
}

$webappExpectedSubnetId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$($deploymentParameters.vnetResourceGroup.value)/providers/Microsoft.Network/virtualNetworks/$($deploymentParameters.vnetName.value)/subnets/$($deploymentParameters.vnetSubnetName.value)"

if ($webappToValidate.VirtualNetworkSubnetId -ne $webappExpectedSubnetId) {
    outputValuesDifferError -parameterName 'WebApp Subnet Id' `
        -expectedValue $webappExpectedSubnetId `
        -actualValue $webappToValidate.VirtualNetworkSubnetId
}

if ($totalErrorCount -eq 0) {
    Write-Output 'Successfully validated the resource. No errors encountered.'
} else {
    Write-Output "There were errors encountered during the validation process. Total error count: $totalErrorCount."
    exit 1
}
