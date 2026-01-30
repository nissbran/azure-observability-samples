param location string = resourceGroup().location
param name string

resource loganalytics_workspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: 'logs${name}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appinsights${name}'
  kind: 'web'
  location: location
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: loganalytics_workspace.id
  }
}

output appinsightsName string = appinsights.name
output workspaceId string = loganalytics_workspace.id
