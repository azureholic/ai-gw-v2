using 'main.bicep'

param environment = 'acc'

param suffix = 'genaishared'

param rgLocation = 'westeurope'

param apimPublisherEmail = 'noreply@microsoft.com'

param apimPublisherName = 'GenAI Lab'

param apimSku = 'StandardV2'

param openAILocations = [
  {
    name: 'westeurope'
    abbreviation: 'we'
    deployments: [
      // {
      //   deploymentName: 'text-embedding-ada-002'
      //   skuName: 'Standard'
      //   skuCapacity: 1
      //   name: 'text-embedding-ada-002'
      //   version: '2'
      //   priority: 1
      // }
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
      // {
      //   deploymentName: 'gpt-4o-2024-08-06'
      //   skuName: 'DataZoneStandard'
      //   skuCapacity: 10
      //   name: 'gpt-4o'
      //   version: '2024-08-06'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'o3-mini-2025-01-31'
      //   skuName: 'DataZoneStandard'
      //   skuCapacity: 10
      //   name: 'o3-mini'
      //   version: '2025-01-31'
      //   priority: 2
      // }
    ]
  }
  {
    name: 'swedencentral'
    abbreviation: 'sc'
    deployments: [
      // {
      //   deploymentName: 'gpt-4-turbo-2024-04-09'
      //   skuName: 'Standard'
      //   skuCapacity: 10
      //   name: 'gpt-4'
      //   version: 'turbo-2024-04-09'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4-0613'
      //   skuName: 'Standard'
      //   skuCapacity: 10
      //   name: 'gpt-4'
      //   version: '0613'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4-1106-Preview'
      //   skuName: 'Standard'
      //   skuCapacity: 10
      //   name: 'gpt-4'
      //   version: '1106-Preview'
      //   priority: 1
      // }
      // Not yet available as pay-as-you-go, only PTU in FC
      // {
      //   deploymentName: 'gpt-4-0125-Preview'
      //   skuName: 'Standard'
      //   skuCapacity: 1
      //   name: 'gpt-4'
      //   version: '0125-Preview'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4-32k-0613'
      //   skuName: 'Standard'
      //   skuCapacity: 1
      //   name: 'gpt-4-32k'
      //   version: '0613'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'text-embedding-ada-002'
      //   skuName: 'Standard'
      //   skuCapacity: 550
      //   name: 'text-embedding-ada-002'
      //   version: '2'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'text-embedding-3-large-1'
      //   skuName: 'Standard'
      //   skuCapacity: 230
      //   name: 'text-embedding-3-large'
      //   version: '1'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4o-2024-05-13'
      //   skuName: 'Standard'
      //   skuCapacity: 20
      //   name: 'gpt-4o'
      //   version: '2024-05-13'
      //   priority: 1
      // }
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
      // {
      //   deploymentName: 'gpt-4o-2024-08-06-standard'
      //   skuName: 'Standard'
      //   skuCapacity: 10
      //   name: 'gpt-4o'
      //   version: '2024-08-06'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4o-2024-08-06'
      //   skuName: 'DataZoneStandard'
      //   skuCapacity: 10
      //   name: 'gpt-4o'
      //   version: '2024-08-06'
      //   priority: 2
      // }
      // {
      //   deploymentName: 'o1-2024-09-12'
      //   skuName: 'Standard'
      //   skuCapacity: 50
      //   name: 'o1-preview'
      //   version: '2024-09-12'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'o1-mini-2024-09-12'
      //   skuName: 'Standard'
      //   skuCapacity: 50
      //   name: 'o1-mini'
      //   version: '2024-09-12'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'o3-mini-2025-01-31'
      //   skuName: 'DataZoneStandard'
      //   skuCapacity: 10
      //   name: 'o3-mini'
      //   version: '2025-01-31'
      //   priority: 1
      // }
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
      // {
      //   deploymentName: 'gpt-4-0613'
      //   skuName: 'Standard'
      //   skuCapacity: 1
      //   name: 'gpt-4'
      //   version: '0613'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4-1106-Preview'
      //   skuName: 'Standard'
      //   skuCapacity: 1
      //   name: 'gpt-4'
      //   version: '1106-Preview'
      //   priority: 1
      // }
      // Not yet available as pay-as-you-go, only PTU in FC
      // {
      //   deploymentName: 'gpt-4-0125-Preview'
      //   skuName: 'Standard'
      //   skuCapacity: 1
      //   name: 'gpt-4'
      //   version: '0125-Preview'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4-32k-0613'
      //   skuName: 'Standard'
      //   skuCapacity: 1
      //   name: 'gpt-4-32k'
      //   version: '0613'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'text-embedding-ada-002'
      //   skuName: 'Standard'
      //   skuCapacity: 240
      //   name: 'text-embedding-ada-002'
      //   version: '2'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'text-embedding-3-large-1'
      //   skuName: 'Standard'
      //   skuCapacity: 350
      //   name: 'text-embedding-3-large'
      //   version: '1'
      //   priority: 1
      // }
      // {
      //   deploymentName: 'gpt-4o-2024-08-06'
      //   skuName: 'DataZoneStandard'
      //   skuCapacity: 300
      //   name: 'gpt-4o'
      //   version: '2024-08-06'
      //   priority: 3
      // }
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
      // {
      //   deploymentName: 'o3-mini-2025-01-31'
      //   skuName: 'DataZoneStandard'
      //   skuCapacity: 20
      //   name: 'o3-mini'
      //   version: '2025-01-31'
      //   priority: 3
      // }
    ]
  }
]
