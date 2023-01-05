#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $deploymentResourceGroupName,
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

$deploymentParameters = (Get-Content $deploymentParametersPath | ConvertFrom-Json).parameters

if ($null -eq $deploymentParameters) {
    Write-Error 'Deployment file specified could not be found.'
    exit 1
}

$aspToValidate = Get-AzResource -Name $deploymentParameters.aspName.value `
    -ResourceType 'Microsoft.Web/serverfarms' `
    -ResourceGroupName $deploymentResourceGroupName

if ($null -eq $aspToValidate) {
    Write-Error "ASP '$($deploymentParameters.aspName.value)' could not be found."
    exit 1
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

$autoscaleToValidate = (Get-AzResource -Name "$($deploymentParameters.aspName.value)-autoscale" `
    -ResourceType 'Microsoft.Insights/autoscalesettings' `
    -ResourceGroupName $deploymentResourceGroupName).Properties
    
if ($null -eq $autoscaleToValidate) {
    Write-Error 'Autoscale specified could not be found.'
    exit 1
}

if ($autoscaleToValidate.Profiles.Capacity.Minimum -ne $deploymentParameters.autoscaleMinimumCapacity.value) {
    outputValuesDifferError -parameterName 'Autoscale Minimum Capacity' `
        -expectedValue $deploymentParameters.autoscaleMinimumCapacity.value `
        -actualValue $autoscaleToValidate.Profiles.Capacity.Minimum
}

if ($autoscaleToValidate.Profiles.Capacity.Maximum -ne $deploymentParameters.autoscaleMaximumCapacity.value) {
    outputValuesDifferError -parameterName 'Autoscale Maximum Capacity' `
        -expectedValue $deploymentParameters.autoscaleMaximumCapacity.value `
        -actualValue $autoscaleToValidate.Profiles.Capacity.Maximum
}

if ($autoscaleToValidate.Profiles.Capacity.Default -ne $deploymentParameters.autoscaleDefaultCapacity.value) {
    outputValuesDifferError -parameterName 'Autoscale Default Capacity' `
        -expectedValue $deploymentParameters.autoscaleDefaultCapacity.value `
        -actualValue $aspToValidate.Capacity.Default
}

$autoscaleMemoryTriggeredIncreaseRule = [array]::Find($autoscaleToValidate.Profiles.Rules, [Predicate[object]]{param([object]$rule) $rule.MetricTrigger.MetricName -eq 'MemoryPercentage' -and $rule.ScaleAction.Direction -eq 'Increase'})

if ($autoscaleMemoryTriggeredIncreaseRule.MetricTrigger.TimeWindow -ne $deploymentParameters.memoryRuleTimeWindow.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Increase Rule Time Window' `
        -expectedValue $deploymentParameters.memoryRuleTimeWindow.value `
        -actualValue $autoscaleMemoryTriggeredIncreaseRule.MetricTrigger.TimeWindow
}

if ($autoscaleMemoryTriggeredIncreaseRule.ScaleAction.Cooldown -ne $deploymentParameters.memoryRuleCooldown.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Increase Rule Cooldown' `
        -expectedValue $deploymentParameters.memoryRuleCooldown.value `
        -actualValue $autoscaleMemoryTriggeredIncreaseRule.ScaleAction.Cooldown
}

if ($autoscaleMemoryTriggeredIncreaseRule.ScaleAction.Value -ne $deploymentParameters.memoryRuleIncreaseBy.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Increase Rule Increase Value' `
        -expectedValue $deploymentParameters.memoryRuleIncreaseBy.value `
        -actualValue $autoscaleMemoryTriggeredIncreaseRule.ScaleAction.Value
}

if ($autoscaleMemoryTriggeredIncreaseRule.MetricTrigger.Threshold -ne $deploymentParameters.memoryRuleIncreaseThreshold.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Increase Rule Threshold' `
        -expectedValue $deploymentParameters.memoryRuleIncreaseThreshold.value `
        -actualValue $autoscaleMemoryTriggeredIncreaseRule.MetricTrigger.Threshold
}

$autoscaleMemoryTriggeredDecreaseRule = [array]::Find($autoscaleToValidate.Profiles.Rules, [Predicate[object]]{param([object]$rule) $rule.MetricTrigger.MetricName -eq 'MemoryPercentage' -and $rule.ScaleAction.Direction -eq 'Decrease'})

if ($autoscaleMemoryTriggeredDecreaseRule.MetricTrigger.TimeWindow -ne $deploymentParameters.memoryRuleTimeWindow.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Decrease Rule Time Window' `
        -expectedValue $deploymentParameters.memoryRuleTimeWindow.value `
        -actualValue $autoscaleMemoryTriggeredDecreaseRule.MetricTrigger.TimeWindow
}

if ($autoscaleMemoryTriggeredDecreaseRule.ScaleAction.Cooldown -ne $deploymentParameters.memoryRuleCooldown.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Decrease Rule Cooldown' `
        -expectedValue $deploymentParameters.memoryRuleCooldown.value `
        -actualValue $autoscaleMemoryTriggeredDecreaseRule.ScaleAction.Cooldown
}

if ($autoscaleMemoryTriggeredDecreaseRule.ScaleAction.Value -ne $deploymentParameters.memoryRuleDecreaseBy.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Decrease Rule Decrease Value' `
        -expectedValue $deploymentParameters.memoryRuleDecreaseBy.value `
        -actualValue $autoscaleMemoryTriggeredDecreaseRule.ScaleAction.Value
}

if ($autoscaleMemoryTriggeredDecreaseRule.MetricTrigger.Threshold -ne $deploymentParameters.memoryRuleDecreaseThreshold.value) {
    outputValuesDifferError -parameterName 'Autoscale Memory-Triggered Decrease Rule Threshold' `
        -expectedValue $deploymentParameters.memoryRuleDecreaseThreshold.value `
        -actualValue $autoscaleMemoryTriggeredDecreaseRule.MetricTrigger.Threshold
}

$autoscaleCpuTriggeredIncreaseRule = [array]::Find($autoscaleToValidate.Profiles.Rules, [Predicate[object]]{param([object]$rule) $rule.MetricTrigger.MetricName -eq 'CpuPercentage' -and $rule.ScaleAction.Direction -eq 'Increase'})

if ($autoscaleCpuTriggeredIncreaseRule.MetricTrigger.TimeWindow -ne $deploymentParameters.cpuRuleTimeWindow.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Increase Rule Time Window' `
        -expectedValue $deploymentParameters.cpuRuleTimeWindow.value `
        -actualValue $autoscaleCpuTriggeredIncreaseRule.MetricTrigger.TimeWindow
}

if ($autoscaleCpuTriggeredIncreaseRule.ScaleAction.Cooldown -ne $deploymentParameters.cpuRuleCooldown.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Increase Rule Cooldown' `
        -expectedValue $deploymentParameters.cpuRuleCooldown.value `
        -actualValue $autoscaleCpuTriggeredIncreaseRule.ScaleAction.Cooldown
}

if ($autoscaleCpuTriggeredIncreaseRule.ScaleAction.Value -ne $deploymentParameters.cpuRuleIncreaseBy.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Increase Rule Increase Value' `
        -expectedValue $deploymentParameters.cpuRuleIncreaseBy.value `
        -actualValue $autoscaleCpuTriggeredIncreaseRule.ScaleAction.Value
}

if ($autoscaleCpuTriggeredIncreaseRule.MetricTrigger.Threshold -ne $deploymentParameters.cpuRuleIncreaseThreshold.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Increase Rule Threshold' `
        -expectedValue $deploymentParameters.cpuRuleIncreaseThreshold.value `
        -actualValue $autoscaleCpuTriggeredIncreaseRule.MetricTrigger.Threshold
}

$autoscaleCpuTriggeredDecreaseRule = [array]::Find($autoscaleToValidate.Profiles.Rules, [Predicate[object]]{param([object]$rule) $rule.MetricTrigger.MetricName -eq 'CpuPercentage' -and $rule.ScaleAction.Direction -eq 'Decrease'})

if ($autoscaleCpuTriggeredDecreaseRule.MetricTrigger.TimeWindow -ne $deploymentParameters.cpuRuleTimeWindow.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Decrease Rule Time Window' `
        -expectedValue $deploymentParameters.cpuRuleTimeWindow.value `
        -actualValue $autoscaleCpuTriggeredDecreaseRule.MetricTrigger.TimeWindow
}

if ($autoscaleCpuTriggeredDecreaseRule.ScaleAction.Cooldown -ne $deploymentParameters.cpuRuleCooldown.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Decrease Rule Cooldown' `
        -expectedValue $deploymentParameters.cpuRuleCooldown.value `
        -actualValue $autoscaleCpuTriggeredDecreaseRule.ScaleAction.Cooldown
}

if ($autoscaleCpuTriggeredDecreaseRule.ScaleAction.Value -ne $deploymentParameters.cpuRuleDecreaseBy.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Decrease Rule Decrease Value' `
        -expectedValue $deploymentParameters.cpuRuleDecreaseBy.value `
        -actualValue $autoscaleCpuTriggeredDecreaseRule.ScaleAction.Value
}

if ($autoscaleCpuTriggeredDecreaseRule.MetricTrigger.Threshold -ne $deploymentParameters.cpuRuleDecreaseThreshold.value) {
    outputValuesDifferError -parameterName 'Autoscale CPU-Triggered Decrease Rule Threshold' `
        -expectedValue $deploymentParameters.cpuRuleDecreaseThreshold.value `
        -actualValue $autoscaleCpuTriggeredDecreaseRule.MetricTrigger.Threshold
}

if ($autoscaleToValidate.Enabled -ne $deploymentParameters.enableAutoscale.value) {
    outputValuesDifferError -parameterName 'Is Autoscale Enabled' `
        -expectedValue $deploymentParameters.enableAutoscale.value `
        -actualValue $autoscaleToValidate.Enabled
}

if ($totalErrorCount -eq 0) {
    Write-Output 'Successfully validated the resource. No errors encountered.'
} else {
    Write-Output "There were errors encountered during the validation process. Total error count: $totalErrorCount."
    exit 1
}