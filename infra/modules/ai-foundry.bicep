@description('The name of the AI Foundry account')
param accountName string

@description('The name of the AI Foundry project')
param projectName string = 'ai-proxy-models'

@description('The location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('The SKU name for the AI Foundry account')
param skuName string = 'S0'

@description('Enable public network access')
param publicNetworkAccess bool = true

@description('Project description')
param projectDescription string = 'AI Proxy model deployments project'

@description('Project display name')
param projectDisplayName string = 'AI Proxy Models'

// AI Foundry Account (Cognitive Services)
resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: accountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiProperties: {}
    customSubDomainName: accountName
    allowProjectManagement: true
    networkAcls: {
      defaultAction: publicNetworkAccess ? 'Allow' : 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: publicNetworkAccess ? 'Enabled' : 'Disabled'
    restrictOutboundNetworkAccess: false
    disableLocalAuth: false
  }
}

// AI Foundry Project
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: aiFoundryAccount
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: projectDisplayName
  }
}

// Outputs
@description('The resource ID of the AI Foundry Account')
output accountId string = aiFoundryAccount.id

@description('The name of the AI Foundry Account')
output accountName string = aiFoundryAccount.name

@description('The endpoint URL of the AI Foundry Account')
output endpoint string = aiFoundryAccount.properties.endpoint

@description('The resource ID of the AI Foundry Project')
output projectId string = aiProject.id

@description('The name of the AI Foundry Project')
output projectName string = aiProject.name

@description('The managed identity principal ID of the account')
output accountPrincipalId string = aiFoundryAccount.identity.principalId

@description('The managed identity principal ID of the project')
output projectPrincipalId string = aiProject.identity.principalId
