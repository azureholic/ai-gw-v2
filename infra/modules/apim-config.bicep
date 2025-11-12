@description('The name of the APIM service')
param apimServiceName string

@description('Named value configurations')
param namedValues array

// Reference existing APIM service
resource apimService 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: apimServiceName
}

// Create named values
@batchSize(1)
resource namedValue 'Microsoft.ApiManagement/service/namedValues@2023-09-01-preview' = [for value in namedValues: {
  parent: apimService
  name: value.name
  properties: {
    displayName: value.displayName
    value: value.value
    secret: value.?secret ?? false
    tags: value.?tags ?? []
  }
}]

// Outputs
@description('Created named value names')
output namedValueNames array = [for (value, i) in namedValues: namedValue[i].name]

@description('Named value details')
output namedValueDetails array = [for (value, i) in namedValues: {
  name: namedValue[i].name
  displayName: value.displayName
  secret: value.?secret ?? false
}]
