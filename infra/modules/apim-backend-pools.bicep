@description('The name of the APIM service')
param apimServiceName string

@description('Backend pool configurations grouped by deployment name')
param backendPools array

// Reference existing APIM service
resource apimService 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: apimServiceName
}

// Create backend pools with priority-based routing
@batchSize(1)
resource pools 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = [for pool in backendPools: {
  parent: apimService
  name: pool.poolName
  properties: {
    description: 'Backend pool for ${pool.deploymentName}'
    type: 'Pool'
    pool: {
      services: [for backend in pool.backends: {
        id: '/backends/${backend.backendId}'
        priority: backend.priority
      }]
    }
  }
}]

// Outputs
@description('Created backend pool names')
output poolNames array = [for (pool, i) in backendPools: pools[i].name]

@description('Backend pool details')
output poolDetails array = [for (pool, i) in backendPools: {
  poolName: pools[i].name
  deploymentName: pool.deploymentName
  backendCount: length(pool.backends)
  backends: pool.backends
}]
