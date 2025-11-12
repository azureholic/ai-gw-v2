@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Name of the custom table')
param tableName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource customTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: logAnalyticsWorkspace
  name: tableName
  properties: {
    schema: {
      name: tableName
      columns: [
        {
          name: 'TimeGenerated'
          type: 'datetime'
          description: 'Timestamp when the log entry was generated'
        }
        {
          name: 'RequestId'
          type: 'string'
          description: 'Unique identifier for the API request'
        }
        {
          name: 'API'
          type: 'string'
          description: 'Name of the API being called'
        }
        {
          name: 'Operation'
          type: 'string'
          description: 'Name of the operation being performed'
        }
        {
          name: 'Subscription'
          type: 'string'
          description: 'Name of the APIM subscription'
        }
        {
          name: 'Model'
          type: 'string'
          description: 'AI model name (e.g., gpt-4o-mini-2024-07-18)'
        }
        {
          name: 'Streaming'
          type: 'boolean'
          description: 'Whether the request was streaming or non-streaming'
        }
        {
          name: 'PromptTokens'
          type: 'real'
          description: 'Number of tokens in the prompt'
        }
        {
          name: 'CompletionTokens'
          type: 'real'
          description: 'Number of tokens in the completion/response'
        }
        {
          name: 'TotalTokens'
          type: 'real'
          description: 'Total number of tokens (prompt + completion)'
        }
        {
          name: 'ResponseTimeMs'
          type: 'real'
          description: 'Response time in milliseconds'
        }
      ]
    }
    retentionInDays: 30
    totalRetentionInDays: 30
  }
}

output tableName string = customTable.name
