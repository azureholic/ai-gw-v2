@description('The name of the user-assigned managed identity')
param managedIdentityName string

@description('The name of the existing AI Foundry account')
param aiFoundryAccountName string

@description('Location for resources')
param location string = resourceGroup().location

// Create user-assigned managed identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

// Reference existing AI Foundry account
resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: aiFoundryAccountName
}

// Role assignments for AI Foundry account access
// Cognitive Services User role for general access
resource cognitiveServicesUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundryAccount.id, managedIdentity.id, 'CognitiveServicesUser')
  scope: aiFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908') // Cognitive Services User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Cognitive Services OpenAI User role for OpenAI endpoints
resource cognitiveServicesOpenAIUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundryAccount.id, managedIdentity.id, 'CognitiveServicesOpenAIUser')
  scope: aiFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Developer role for comprehensive access
resource aiDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundryAccount.id, managedIdentity.id, 'AzureAIDeveloper')
  scope: aiFoundryAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '64702f94-c441-49e6-a78b-ef80e0188fee') // Azure AI Developer
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
@description('Managed Identity information')
output managedIdentity object = {
  id: managedIdentity.id
  name: managedIdentity.name
  principalId: managedIdentity.properties.principalId
  clientId: managedIdentity.properties.clientId
}

@description('Role assignments information')
output roleAssignments array = [
  {
    role: 'Cognitive Services User'
    assignmentId: cognitiveServicesUserRole.id
  }
  {
    role: 'Cognitive Services OpenAI User' 
    assignmentId: cognitiveServicesOpenAIUserRole.id
  }
  {
    role: 'Azure AI Developer'
    assignmentId: aiDeveloperRole.id
  }
]

@description('Instructions for APIM identity assignment')
output apimIdentityInstructions string = 'Run: az apim update --resource-group ${resourceGroup().name} --name [APIM-NAME] --assign-identity ${managedIdentity.id}'
