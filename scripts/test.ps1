$deploymentParameters = (Get-Content '.\parameters\webapp-deploy.parameters-java.json' | ConvertFrom-Json).parameters

$webappToValidate = Set-AzWebApp -Name 'test-wapp02-9f3ed10c-c29' -ResourceGroupName 'test-rg01'

$allRestrictedIps = new-object system.collections.arraylist

foreach ($restriction in $webappToValidate.SiteConfig.IpSecurityRestrictions) {
    Write-Output $restriction.IpAddress
}

Write-Output $allIps.Count

$webappToValidate.SiteConfig.IpSecurityRestrictions -contains $deploymentParameters.webappIpRestrictions.value[0]