targetScope = 'subscription'

param rgNameOp string = 'rg-observability-aks-app'
param rgNameApp string = 'rg-application-aks-app'
param location string = 'northeurope'
param nameSuffix string = 'app-01'
param alertEmailAddress array

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: 'apim-${nameSuffix}'
  scope: resourceGroup(rgNameApp)
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-01-01' existing = {
  name: 'aks-${nameSuffix}'
  scope: resourceGroup(rgNameApp)
}
resource amw_workspace 'Microsoft.Monitor/accounts@2023-04-03' existing = {
  name: 'amw-${nameSuffix}'
  scope: resourceGroup(rgNameOp)
}

module alerts 'core/monitoring/alerts/alerts.bicep' = {
  scope: resourceGroup(rgNameOp)
  name: 'cluster_alerts'
  params: {
    aksResourceId: aks.id
    emailAddress: alertEmailAddress
    location: location
    apimResourceId: apim.id
    monitorWorkspaceId: amw_workspace.id
  }
}
