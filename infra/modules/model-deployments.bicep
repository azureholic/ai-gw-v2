@description('The name of the existing AI Foundry account')
param accountName string

@description('The name of the existing AI Foundry project')
param projectName string = 'ai-proxy-models'

@description('The name of the APIM service for backend creation')
param apimServiceName string

@description('Region abbreviation for unique backend naming')
param regionAbbreviation string

@description('Model deployments configuration')
param modelDeployments array = []

// Reference existing AI Foundry Account
resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
}

// Reference existing AI Foundry Project
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = {
  parent: aiFoundryAccount
  name: projectName
}

// Reference existing APIM service
resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimServiceName
}

// Create model deployments (sequential deployment with batch size 1)
@batchSize(1)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-04-01-preview' = [for (deployment, index) in modelDeployments: {
  parent: aiFoundryAccount
  name: deployment.deploymentName
  properties: {
    model: {
      format: deployment.model.format
      name: deployment.model.name
      version: deployment.model.version
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: deployment.sku.capacity
    raiPolicyName: deployment.?raiPolicyName
  }
  sku: {
    name: deployment.sku.name
    capacity: deployment.sku.capacity
  }
}]

// Create single APIM backend for Azure OpenAI native endpoint per region
resource apimBackendAzureOpenAI 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apimService
  name: 'aoai-${regionAbbreviation}'
  properties: {
    description: 'Azure Cognitive Services backend for AI Foundry project in ${regionAbbreviation}'
    url: aiFoundryAccount.properties.endpoint
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
  dependsOn: [
    modelDeployment
  ]
}

// Outputs
@description('The deployed models with backend information')
output deployedModels array = [for (deployment, index) in modelDeployments: {
  deploymentName: deployment.deploymentName
  modelName: deployment.model.name
  modelVersion: deployment.model.version
  modelFormat: deployment.model.format
  priority: deployment.?priority ?? 1
  regionAbbreviation: regionAbbreviation
}]

@description('Regional backend IDs')
output aoaiBackendId string = apimBackendAzureOpenAI.name

@description('The AI Foundry account endpoint')
output aiFoundryEndpoint string = aiFoundryAccount.properties.endpoint

@description('The AI Foundry API endpoint (for Microsoft format models)')
output aiFoundryApiEndpoint string = aiFoundryAccount.properties.endpoints['AI Foundry API']

@description('The project resource ID')
output projectId string = aiProject.id
