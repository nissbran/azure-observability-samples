targetScope = 'resourceGroup'

param workspaceName string
@allowed(['Basic', 'Analytics'])
param tablePlan string = 'Analytics'

resource la 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource tomcatTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  name: 'TomcatLogs_CL'
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
          name: 'FilePath'
          type: 'string'
          displayName: 'FilePath'
          description: 'File path of the log file'
         }
      ]
      displayName: 'TomcatLogs'
      name: 'TomcatLogs_CL'
    }
  }
}
