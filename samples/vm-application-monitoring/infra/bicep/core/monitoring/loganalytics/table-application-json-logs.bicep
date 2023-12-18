targetScope = 'resourceGroup'

param workspaceName string
@allowed(['Basic', 'Analytics'])
param tablePlan string = 'Analytics'

resource la 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource jsonLogs 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  name: 'ApplicationJsonLogs_CL'
  parent: la
  properties: {
    plan: tablePlan // Analytics can be used.
    retentionInDays: tablePlan == 'Analytics' ? 30 : null
    totalRetentionInDays: tablePlan == 'Analytics' ? 90 : 30
    schema: {
      columns: [
         {
          name: 'TimeGenerated'
          type: 'datetime'
          displayName: 'TimeGenerated'
          description: 'Time when event was generated'
         }
         {
          name: 'Timestamp'
          type: 'datetime'
          displayName: 'Timestamp'
          description: 'Time when log written in the logs'
         }
         {
          name: 'Level'
          type: 'string'
          displayName: 'Level'
          description: 'Log level'
         }
         {
          name: 'Message'
          type: 'string'
          displayName: 'Message'
          description: 'Log message'
         }
         {
          name: 'Properties'
          type: 'dynamic'
          displayName: 'Properties'
          description: 'Log properties'
         }
      ]
      displayName: 'ApplicationJsonLogs'
      description: 'Application Json Logs'
      name: 'ApplicationJsonLogs_CL'
    }
  }
}
