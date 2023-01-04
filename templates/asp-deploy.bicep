@description('A name for an ASP.')
@minLength(3)
@maxLength(24)
param aspName string

@allowed([
  'windows'
  'linux'
])
param aspKind string

@description('Location for an ASP.')
param aspLocation string = resourceGroup().location

@description('The name of SKU to use for the ASP deployment.')
param aspSkuName string

@description('The pricing tier for the ASP.')
@allowed([
  'Standard'
  'Premium'
])
param aspSkuTier string = 'Standard'

@description('The capacity of SKU to use for the ASP deployment.')
param aspSkuCapacity int

@description('Minimum instance count for ASP affected by the autoscale.')
param autoscaleMinimumCapacity string

@description('Maximum instance count for ASP affected by the autoscale.')
param autoscaleMaximumCapacity string

@description('Default instance count for ASP affected by the autoscale.')
param autoscaleDefaultCapacity string

@description('Determines the time window used for evaluating both increase and decrease memory-percentage-triggered rules.')
param memoryRuleTimeWindow string = 'PT10M'

@description('Specifies cooldown between the re-evaluation of both memory-percentage-triggered rules.')
param memoryRuleCooldown string = 'PT10M'

@description('Determines how many instances are added if "memoryRuleIncreaseThreshold" is reached.')
param memoryRuleIncreaseBy string = '1'

@description('Specifies the percentage of memory usage in a time window specified upon reaching which webapp instance count should be increased.')
param memoryRuleIncreaseThreshold int = 80

@description('Determines how many instances are removed if "memoryRuleDecreaseThreshold" is effectively above the current memory usage in percentage.')
param memoryRuleDecreaseBy string = '1'

@description('Specifies the percentage of memory usage in a time window specified upon falling bellow which webapp instance count should be decreased.')
param memoryRuleDecreaseThreshold int = 60

@description('Determines the time window used for evaluating both increase and decrease cpu-percentage-triggered rules.')
param cpuRuleTimeWindow string = 'PT10M'

@description('Specifies cooldown between the re-evaluation of both cpu-percentage-triggered rules.')
param cpuRuleCooldown string = 'PT10M'

@description('Determines how many instances are added if "cpuRuleIncreaseThreshold" is reached.')
param cpuRuleIncreaseBy string = '1'

@description('Specifies the percentage of cpu usage in a time window specified upon reaching which webapp instance count should be increased.')
param cpuRuleIncreaseThreshold int = 80

@description('Determines how many instances are removed if "cpuRuleDecreaseThreshold" is effectively above the current memory usage in percentage.')
param cpuRuleDecreaseBy string = '1'

@description('Specifies the percentage of cpu usage in a time window specified upon falling bellow which webapp instance count should be decreased.')
param cpuRuleDecreaseThreshold int = 60

@description('Determines whether provisioned autoscale should be automatically enabled.')
param enableAutoscale bool

var autoscaleName = '${toLower(aspName)}-autoscale'

resource asp 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: aspName
  kind: aspKind
  location: aspLocation
  sku: {
    name: aspSkuName
    tier: aspSkuTier
    capacity: aspSkuCapacity
  }
  properties: {
    reserved: aspKind == 'linux' ? true : false
  }
}

resource autoscale 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  name: autoscaleName
  location: aspLocation
  properties: {
    profiles: [
      {
        name: 'DefaultAutoscaleProfile'
        capacity: {
          minimum: autoscaleMinimumCapacity
          maximum: autoscaleMaximumCapacity
          default: autoscaleDefaultCapacity
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'MemoryPercentage'
              metricResourceUri: asp.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: memoryRuleTimeWindow
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: memoryRuleIncreaseThreshold
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: memoryRuleIncreaseBy
              cooldown: memoryRuleCooldown
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: asp.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: cpuRuleTimeWindow
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: cpuRuleIncreaseThreshold
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: cpuRuleIncreaseBy
              cooldown: cpuRuleCooldown
            }
          }
          {
            metricTrigger: {
              metricName: 'MemoryPercentage'
              metricResourceUri: asp.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: memoryRuleTimeWindow
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: memoryRuleDecreaseThreshold
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: memoryRuleDecreaseBy
              cooldown: memoryRuleCooldown
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: asp.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: cpuRuleTimeWindow
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: cpuRuleDecreaseThreshold
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: cpuRuleDecreaseBy
              cooldown: cpuRuleCooldown
            }
          }
        ]
      }
    ]
    enabled: enableAutoscale
    targetResourceUri: asp.id
  }
}
