targetScope = 'resourceGroup'

param workspaceName string
@allowed(['Basic', 'Analytics', 'Auxiliary'])
param tablePlan string = 'Auxiliary'

resource la 'Microsoft.OperationalInsights/workspaces@2025-02-01' existing = {
  name: workspaceName
}

// This api version exists, and its needed for auxiliary tables.
#disable-next-line BCP081
resource windowEventsTable 'Microsoft.OperationalInsights/workspaces/tables@2023-01-01-preview' = {
  name: 'WindowEvents_CL'
  parent: la
  properties: {
    plan: tablePlan
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
          name: 'Message'
          type: 'string'
          displayName: 'Message'
          description: 'Log message'
         }
         {
          name: 'EventType'
          type: 'string'
          displayName: 'EventType'
          description: 'Type of the event'
         }
         {
          name: 'EventID'
          type: 'int'
          displayName: 'EventID'
          description: 'Event ID of the event'
         }
      ]
      displayName: 'WindowEvents'
      name: 'WindowEvents_CL'
    }
  }
}
