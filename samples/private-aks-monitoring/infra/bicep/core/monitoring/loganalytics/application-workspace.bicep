targetScope = 'resourceGroup'

param nameSuffix string
param privateAccess bool
param networkResourceGroup string
param location string = resourceGroup().location

var laName = 'logs-${nameSuffix}'

resource loganalytics_workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: laName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: privateAccess ? 'Disabled' : 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module connectToPls '../connect-to-monitor-pls.bicep' = if (privateAccess) {
  name: 'pls-${laName}-connection'
  scope: resourceGroup(networkResourceGroup)
  params:{
    resourceId: loganalytics_workspace.id
    resourceName: loganalytics_workspace.name 
  }
}

output workspaceName string = loganalytics_workspace.name
output workspaceId string = loganalytics_workspace.id
