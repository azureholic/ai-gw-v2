targetScope = 'resourceGroup'

// Parameters
@description('Environment name (e.g., acc, prd)')
param environment string

@description('Suffix for resource naming')
param suffix string

@description('Unique identifier for deployment (default: resource group-based unique string)')
param uniqueId string = uniqueString(resourceGroup().id)

@description('Primary location for resources (except AI Foundry projects)')
param rgLocation string

@description('APIM publisher email')
param apimPublisherEmail string

@description('APIM publisher name')
param apimPublisherName string

@description('APIM SKU')
param apimSku string

@description('OpenAI locations with deployments')
param openAILocations array

@description('Tags to apply to all resources')
param tags object = {}

// Variables
var namingPrefix = '${environment}-${suffix}'
var apimName = 'apim-${namingPrefix}-${uniqueId}'
var managedIdentityName = 'id-apim-${namingPrefix}'
var logAnalyticsName = 'law-${namingPrefix}'
var appInsightsName = 'appi-${namingPrefix}'

// 1. Create user-assigned managed identity for APIM
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: rgLocation
  tags: tags
}

// 2. Deploy monitoring infrastructure
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'deploy-log-analytics'
  params: {
    location: rgLocation
    workspaceName: logAnalyticsName
    retentionInDays: 30
  }
}

module appInsights 'modules/app-insights.bicep' = {
  name: 'deploy-app-insights'
  params: {
    appInsightsName: appInsightsName
    location: rgLocation
    tags: tags
    workspaceResourceId: logAnalytics.outputs.workspaceResourceId
  }
}

// 3. Deploy multi-region AI Foundry accounts and projects
@batchSize(1)
module aiFoundry 'modules/ai-foundry.bicep' = [for (location, i) in openAILocations: {
  name: 'deploy-aifoundry-${location.abbreviation}'
  params: {
    accountName: 'cog-aifoundry-${environment}-${suffix}-${location.abbreviation}-${uniqueId}'
    projectName: 'ai-proxy-models-${location.abbreviation}-${uniqueId}'
    location: location.name  // Deploy to the specified region
    tags: tags
    skuName: 'S0'
    publicNetworkAccess: true
  }
}]

// 4. Grant RBAC permissions to managed identity
@batchSize(1)
module aiFoundryRbac 'modules/ai-foundry-rbac.bicep' = [for (location, i) in openAILocations: {
  name: 'rbac-aifoundry-${location.abbreviation}'
  params: {
    projectResourceId: aiFoundry[i].outputs.projectId
    principalId: managedIdentity.properties.principalId
    regionAbbreviation: location.abbreviation
  }
  dependsOn: [
    aiFoundry[i]
  ]
}]

// 5. Deploy APIM service
module apim 'modules/apim.bicep' = {
  name: 'deploy-apim'
  params: {
    apimName: apimName
    location: rgLocation
    tags: tags
    sku: apimSku
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    managedIdentityId: managedIdentity.id
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    appInsightsId: appInsights.outputs.appInsightsId
  }
}

// 6. Deploy models per region
@batchSize(1)
module modelDeployments 'modules/model-deployments.bicep' = [for (location, i) in openAILocations: {
  name: 'deploy-models-${location.abbreviation}'
  params: {
    accountName: 'cog-aifoundry-${environment}-${suffix}-${location.abbreviation}-${uniqueId}'
    projectName: 'ai-proxy-models-${location.abbreviation}-${uniqueId}'
    apimServiceName: apimName
    regionAbbreviation: location.abbreviation
    modelDeployments: [for deployment in location.deployments: {
      deploymentName: deployment.deploymentName
      model: {
        format: 'OpenAI'
        name: deployment.name
        version: deployment.version
      }
      sku: {
        name: deployment.skuName
        capacity: deployment.skuCapacity
      }
      priority: deployment.?priority ?? 1
    }]
  }
  dependsOn: [
    aiFoundry[i]
    aiFoundryRbac[i]
    apim
  ]
}]

// 7. Create backend pools by grouping backends by deployment name
// Extract unique deployment names from all regions
var region0Deployments = [for deployment in openAILocations[0].deployments: deployment.deploymentName]
var region1Deployments = [for deployment in openAILocations[1].deployments: deployment.deploymentName]
var region2Deployments = [for deployment in openAILocations[2].deployments: deployment.deploymentName]
var allDeploymentNames = union(region0Deployments, union(region1Deployments, region2Deployments))

// Create backend pool configurations - one pool per model with regional backends
var aoaiBackendPoolConfigs = [for (deploymentName, idx) in allDeploymentNames: {
  poolName: 'pool-aoai-${replace(deploymentName, '.', '-dot-')}'
  deploymentName: deploymentName
  backends: union(
    contains(region0Deployments, deploymentName) ? [{
      backendId: 'aoai-${openAILocations[0].abbreviation}'
      priority: openAILocations[0].deployments[indexOf(region0Deployments, deploymentName)].?priority ?? 1
    }] : [],
    union(
      contains(region1Deployments, deploymentName) ? [{
        backendId: 'aoai-${openAILocations[1].abbreviation}'
        priority: openAILocations[1].deployments[indexOf(region1Deployments, deploymentName)].?priority ?? 2
      }] : [],
      contains(region2Deployments, deploymentName) ? [{
        backendId: 'aoai-${openAILocations[2].abbreviation}'
        priority: openAILocations[2].deployments[indexOf(region2Deployments, deploymentName)].?priority ?? 3
      }] : []
    )
  )
}]

module aoaiBackendPools 'modules/apim-backend-pools.bicep' = {
  name: 'aoai-backend-pools-deployment'
  params: {
    apimServiceName: apim.outputs.apimName
    backendPools: aoaiBackendPoolConfigs
  }
  dependsOn: [
    modelDeployments
  ]
}

// 8. Configure APIM Named Values
module apimConfig 'modules/apim-config.bicep' = {
  name: 'apim-config-deployment'
  params: {
    apimServiceName: apim.outputs.apimName
    namedValues: [
      {
        name: 'managed-identity-client-id'
        displayName: 'managed-identity-client-id'
        value: managedIdentity.properties.clientId
        secret: false
      }
    ]
  }
}

// 9. Apply policies to API operations
module apimPolicies 'modules/apim-policies.bicep' = {
  name: 'apim-policies-deployment'
  params: {
    apimServiceName: apim.outputs.apimName
    aoaiPolicyXml: loadTextContent('../apim-policies/aoai-policy.xml')
    oaiv1PolicyXml: loadTextContent('../apim-policies/oaiv1-policy.xml')
  }
  dependsOn: [
    aoaiBackendPools
    apimConfig
  ]
}

// Outputs
@description('Managed Identity Resource ID')
output managedIdentityId string = managedIdentity.id

@description('Managed Identity Client ID')
output managedIdentityClientId string = managedIdentity.properties.clientId

@description('Managed Identity Principal ID')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('APIM Gateway URL')
output apimGatewayUrl string = apim.outputs.apimGatewayUrl

@description('APIM Service Name')
output apimName string = apim.outputs.apimName

@description('Log Analytics Workspace Resource ID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceResourceId

@description('Application Insights Resource ID')
output appInsightsId string = appInsights.outputs.appInsightsId

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey

@description('Application Insights Connection String')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('AI Foundry Accounts and Projects')
output aiFoundryAccounts array = [for (location, i) in openAILocations: {
  region: location.name
  abbreviation: location.abbreviation
  accountName: aiFoundry[i].outputs.accountName
  accountId: aiFoundry[i].outputs.accountId
  projectId: aiFoundry[i].outputs.projectId
  projectName: aiFoundry[i].outputs.projectName
  endpoint: aiFoundry[i].outputs.endpoint
}]

@description('AOAI Backend Pool Names')
output aoaiBackendPools array = aoaiBackendPools.outputs.poolNames

@description('APIM Named Values')
output apimNamedValues array = apimConfig.outputs.namedValueNames

@description('Deployment Summary')
output deploymentSummary object = {
  resourceGroup: resourceGroup().name
  location: rgLocation
  environment: environment
  managedIdentity: {
    name: managedIdentity.name
    principalId: managedIdentity.properties.principalId
  }
  apim: {
    name: apim.outputs.apimName
    gatewayUrl: apim.outputs.apimGatewayUrl
    sku: 'StandardV2'
  }
  monitoring: {
    workspaceId: logAnalytics.outputs.workspaceResourceId
    appInsightsId: appInsights.outputs.appInsightsId
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
  regionCount: length(openAILocations)
  totalModelDeployments: length(allDeploymentNames)
  backendPools: {
    aoaiCount: length(aoaiBackendPools.outputs.poolNames)
  }
}
