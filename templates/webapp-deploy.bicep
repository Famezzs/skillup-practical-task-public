@description('Name of the ASP to associate the web app with.')
@minLength(3)
@maxLength(24)
param aspName string

@description('Name of the resource group where the ASP associated with the web app resides.')
@minLength(3)
@maxLength(24)
param aspResourceGroupName string

@description('A name for a web app.')
@minLength(3)
@maxLength(24)
param webappName string

@description('Location for a webapp.')
param webappLocation string = resourceGroup().location

@description('Determines the currently running code stack for a Windows web app (e.g. dotnet, java, etc.)')
param webappCurrentStack string

@allowed([
  'Classic'
  'Integrated'
])
param webappManagedPipelineMode string

@allowed([
  'AllAllowed'
  'FtpsOnly'
  'Disabled'
])
param webappFtpsState string
param webappWebSocketsEnabled bool
param webappAlwaysOn bool
param webappRemoteDebuggingEnabled bool

@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param webappMinimumTLSVersion string

@description('Determines whether session-affinity cookies are sent. Setting this to \'true\' makes client forward data to the same back-end instance in the same session.')
param webappClientAffinityEnabled bool

@description('Setting this to \'true\' enables client certificate authentication.')
param webappClientCertificateEnabled bool

@allowed([
  'Optional'
  'OptionalInteractiveUser'
  'Required'
])
param webappClientCertificateMode string
param webappHttpsOnly bool
param webappVnetRouteAll bool
param webappIpRestrictions array
param webappLinuxFrameworkVersion string
param webappJavaVersion string
param webappNodeVersion string
param webappPhpVersion string
param webappPythonVersion string
param webappNetFrameworkVersion string

@description('If provided, the webapp will be connected to the app insights specified by \'appInsightsName\'.')
param appInsightsName string

@description('Name of the resource group where the App Insights the web app should be connected to resides.')
param appInsightsResourceGroupName string = resourceGroup().name

@description('Name of the vnet which contains the subnet specified by \'vnetSubnetName\' that will be used for vnet integration of the webapp.')
@minLength(3)
@maxLength(24)
param vnetName string

@description('Specifies the resource group in which the vnet specified by \'vnetName\' resides. Default value: the resource group into which the webapp is being deployed.')
param vnetResourceGroup string = resourceGroup().name

@description('Specifies the name of subnet which will be used for vnet integration of the webapp being deployed.')
@minLength(3)
@maxLength(24)
param vnetSubnetName string

@description('Setting this to \'true\' enables http 2.0 support.')
param webappHttp20Enabled bool

resource webapp 'Microsoft.Web/sites@2020-12-01' = {
  name: webappName
  location: webappLocation
  properties: {
    serverFarmId: resourceId(aspResourceGroupName, 'Microsoft.Web/serverfarms', aspName)
    siteConfig: {
      managedPipelineMode: webappManagedPipelineMode
      ftpsState: webappFtpsState
      webSocketsEnabled: webappWebSocketsEnabled
      alwaysOn: webappAlwaysOn
      remoteDebuggingEnabled: webappRemoteDebuggingEnabled
      minTlsVersion: webappMinimumTLSVersion
      vnetRouteAllEnabled: webappVnetRouteAll
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: (empty(appInsightsName) ? json('null') : reference(resourceId(appInsightsResourceGroupName, 'Microsoft.Insights/components', appInsightsName), '2015-05-01').InstrumentationKey)
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: (empty(appInsightsName) ? json('null') : reference(resourceId(appInsightsResourceGroupName, 'Microsoft.Insights/components', appInsightsName), '2015-05-01').ConnectionString)
        }
      ]
      metadata: [
        {
          name: 'CURRENT_STACK'
          value: webappCurrentStack
        }
      ]
      ipSecurityRestrictions: webappIpRestrictions
      linuxFxVersion: webappLinuxFrameworkVersion
      netFrameworkVersion: webappNetFrameworkVersion
      javaVersion: webappJavaVersion
      phpVersion: webappPhpVersion
      pythonVersion: webappPythonVersion
      nodeVersion: webappNodeVersion
      http20Enabled: webappHttp20Enabled
    }
    clientAffinityEnabled: webappClientAffinityEnabled
    clientCertEnabled: webappClientCertificateEnabled
    clientCertMode: webappClientCertificateMode
    httpsOnly: webappHttpsOnly
    virtualNetworkSubnetId: ((empty(vnetName) || empty(vnetSubnetName)) ? json('null') : '${subscription().id}/resourceGroups/${vnetResourceGroup}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${vnetSubnetName}')
  }
}
