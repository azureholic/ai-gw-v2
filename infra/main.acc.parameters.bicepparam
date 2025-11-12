using 'main.bicep'

param environment = 'dev'

param suffix = 'genaishared'

param rgLocation = 'westeurope'

param apimPublisherEmail = 'noreply@microsoft.com'

param apimPublisherName = 'AIGatewayTeam'

param apimSku = 'StandardV2'

param openAILocations = [
  {
    name: 'westeurope'
    abbreviation: 'we'
    deployments: [
      {
        deploymentName: 'gpt-4o-mini-2024-07-18'
        skuName: 'DataZoneStandard'
        skuCapacity: 10
        name: 'gpt-4o-mini'
        version: '2024-07-18'
        format: 'OpenAI'
        priority: 1
        raiPolicyName: 'Microsoft.DefaultV2'
      }
    ]
  }
  {
    name: 'swedencentral'
    abbreviation: 'sc'
    deployments: [
      {
        deploymentName: 'gpt-4o-mini-2024-07-18-standard'
        skuName: 'Standard'
        skuCapacity: 30
        name: 'gpt-4o-mini'
        version: '2024-07-18'
        format: 'OpenAI'
        priority: 1
        raiPolicyName: 'Microsoft.DefaultV2'
      }
      {
        deploymentName: 'gpt-4o-mini-2024-07-18'
        skuName: 'DataZoneStandard'
        skuCapacity: 10
        name: 'gpt-4o-mini'
        version: '2024-07-18'
        format: 'OpenAI'
        priority: 2
        raiPolicyName: 'Microsoft.DefaultV2'
      }

      {
        deploymentName: 'Phi-4'
        skuName: 'GlobalStandard'
        skuCapacity: 1
        name: 'Phi-4'
        version: '7'
        format: 'Microsoft'
        priority: 3
        raiPolicyName: 'Microsoft.DefaultV2'
      }
    ]
  }
  {
    name: 'francecentral'
    abbreviation: 'fc'
    deployments: [
      {
        deploymentName: 'gpt-4o-mini-2024-07-18'
        skuName: 'DataZoneStandard'
        skuCapacity: 10
        name: 'gpt-4o-mini'
        version: '2024-07-18'
        format: 'OpenAI'
        priority: 3
        raiPolicyName: 'Microsoft.DefaultV2'
      }
    ]
  }
]
