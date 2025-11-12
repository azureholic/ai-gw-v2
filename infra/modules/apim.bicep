@description('The name of the API Management service')
param apimName string

@description('The location for the APIM service')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('The SKU of the APIM service')
@allowed(['BasicV2', 'StandardV2'])
param sku string = 'StandardV2'

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher name for APIM')
param publisherName string

@description('User-assigned managed identity resource ID')
param managedIdentityId string

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('Application Insights resource ID')
param appInsightsId string

// API Management Service
resource apimService 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: sku == 'Developer' ? 1 : 1
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// Azure OpenAI API (native format) - import from OpenAPI spec
resource azureOpenAIApi 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  parent: apimService
  name: 'azure-openai-api'
  properties: {
    displayName: 'Azure OpenAI Service API'
    description: 'Azure OpenAI native API format'
    path: 'openai'
    protocols: ['https']
    subscriptionRequired: false
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    type: 'http'
    format: 'openapi+json'
    value: loadTextContent('../../openapi/azure-openai-2024-02-01.json')
    serviceUrl: 'https://placeholder.openai.azure.com'
  }
}

// OpenAI v1 API (OpenAI-compatible format) - import from OpenAPI spec
resource openAIv1Api 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  parent: apimService
  name: 'openai-v1-api'
  properties: {
    displayName: 'OpenAI v1 API'
    description: 'OpenAI v1 compatible API format'
    path: 'v1'
    protocols: ['https']
    subscriptionRequired: false
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    type: 'http'
    format: 'openapi+json'
    value: loadTextContent('../../openapi/openai-v1.json')
    serviceUrl: 'https://placeholder.openai.azure.com'
  }
}

// Application Insights logger
resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-09-01-preview' = {
  parent: apimService
  name: 'appinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Application Insights logger for OpenAI APIs'
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
    isBuffered: true
    resourceId: appInsightsId
  }
}

// Diagnostics for Azure OpenAI API
resource azureOpenAIDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2023-09-01-preview' = {
  parent: azureOpenAIApi
  name: 'applicationinsights'
  properties: {
    loggerId: apimLogger.id
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    metrics: true
  }
}

// Diagnostics for OpenAI v1 API
resource openAIv1Diagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2023-09-01-preview' = {
  parent: openAIv1Api
  name: 'applicationinsights'
  properties: {
    loggerId: apimLogger.id
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    metrics: true
  }
}

// Outputs
@description('The resource ID of the APIM service')
output apimId string = apimService.id

@description('The name of the APIM service')
output apimName string = apimService.name

@description('The gateway URL of the APIM service')
output apimGatewayUrl string = apimService.properties.gatewayUrl

@description('The Azure OpenAI API ID')
output azureOpenAIApiId string = azureOpenAIApi.id

@description('The OpenAI v1 API ID')
output openAIv1ApiId string = openAIv1Api.id
