@description('The resource ID of the AI Foundry project')
param projectResourceId string

@description('The principal ID of the managed identity')
param principalId string

@description('Region abbreviation for unique naming')
param regionAbbreviation string

// Parse project resource ID to get account name and project name
var projectIdParts = split(projectResourceId, '/')
var accountName = projectIdParts[8]
var projectName = projectIdParts[10]

// Reference existing AI Foundry account (Cognitive Services account)
resource aiAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
}

// Reference existing AI Foundry project
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = {
  parent: aiAccount
  name: projectName
}

// Cognitive Services OpenAI User role assignment on the ACCOUNT
resource accountCognitiveServicesOpenAIUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiAccount.id, principalId, 'CognitiveServicesOpenAIUser', regionAbbreviation)
  scope: aiAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Cognitive Services OpenAI User role assignment on the PROJECT
resource cognitiveServicesOpenAIUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(projectResourceId, principalId, 'CognitiveServicesOpenAIUser', regionAbbreviation)
  scope: aiProject
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd') // Cognitive Services OpenAI User
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure AI Developer role assignment
resource azureAIDeveloperRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(projectResourceId, principalId, 'AzureAIDeveloper', regionAbbreviation)
  scope: aiProject
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '64702f94-c441-49e6-a78b-ef80e0188fee') // Azure AI Developer
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignments array = [
  {
    role: 'Cognitive Services OpenAI User (Account)'
    roleAssignmentId: accountCognitiveServicesOpenAIUserRole.id
  }
  {
    role: 'Cognitive Services OpenAI User (Project)'
    roleAssignmentId: cognitiveServicesOpenAIUserRole.id
  }
  {
    role: 'Azure AI Developer'
    roleAssignmentId: azureAIDeveloperRole.id
  }
]
