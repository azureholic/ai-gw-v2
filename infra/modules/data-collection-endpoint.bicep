@description('Location for the Data Collection Endpoint')
param location string

@description('Name of the Data Collection Endpoint')
param dceName string

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: dceName
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

output dceResourceId string = dataCollectionEndpoint.id
output logsIngestionEndpoint string = dataCollectionEndpoint.properties.logsIngestion.endpoint
output dceName string = dataCollectionEndpoint.name
