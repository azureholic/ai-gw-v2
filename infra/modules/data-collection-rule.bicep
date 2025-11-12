@description('Location for the Data Collection Rule')
param location string

@description('Name of the Data Collection Rule')
param dcrName string

@description('Resource ID of the Log Analytics workspace')
param workspaceResourceId string

@description('Resource ID of the Data Collection Endpoint')
param dceResourceId string

@description('Name of the custom stream')
param streamName string

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcrName
  location: location
  properties: {
    dataCollectionEndpointId: dceResourceId
    streamDeclarations: {
      '${streamName}': {
        columns: [
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }
          {
            name: 'RequestId'
            type: 'string'
          }
          {
            name: 'API'
            type: 'string'
          }
          {
            name: 'Operation'
            type: 'string'
          }
          {
            name: 'Subscription'
            type: 'string'
          }
          {
            name: 'Model'
            type: 'string'
          }
          {
            name: 'Streaming'
            type: 'boolean'
          }
          {
            name: 'PromptTokens'
            type: 'real'
          }
          {
            name: 'CompletionTokens'
            type: 'real'
          }
          {
            name: 'TotalTokens'
            type: 'real'
          }
          {
            name: 'ResponseTimeMs'
            type: 'real'
          }
        ]
      }
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceResourceId
          name: 'aiUsageWorkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          streamName
        ]
        destinations: [
          'aiUsageWorkspace'
        ]
        transformKql: 'source'
        outputStream: streamName
      }
    ]
  }
}

output dcrResourceId string = dataCollectionRule.id
output immutableId string = dataCollectionRule.properties.immutableId
output dcrName string = dataCollectionRule.name
