param networkResourceGroup string
param privateAccess bool
param deployNetworkWatcher bool
param nameSuffix string
param vnetName string
param location string = resourceGroup().location

module logs_workspace 'loganalytics/application-workspace.bicep' = {
  name: 'logs'
  params: {
    nameSuffix: nameSuffix
    location: location
    networkResourceGroup: networkResourceGroup
    privateAccess: privateAccess
  }
}

// module network_monitoring 'network/network-monitoring.bicep' = {
//   name: 'network_monitoring'
//   params: {
//     vnetName: vnetName
//     networkResourceGroup: networkResourceGroup
//     location: location
//   }
// }

module dce_aks 'dce/dce-aks.bicep' = {
  name: 'dce_aks'
  params: {
    nameSuffix: nameSuffix
    location: location
    networkResourceGroup: networkResourceGroup
    privateAccess: privateAccess
  }
}

module metrics 'metrics/amw.bicep' = {
  name: 'metrics'
  params: {
    nameSuffix: nameSuffix
    location: location
  }
}

module dcr_aks 'dcr/dcr-aks.bicep' = {
  name: 'dcr_aks'
  params: {
    nameSuffix: nameSuffix
    location: location
    dataCollectionEndpointResourceId: dce_aks.outputs.dceId
    logsWorkspaceResourceId: logs_workspace.outputs.workspaceId
    monitorWorkspaceResourceId: metrics.outputs.amwWorkspaceId
  }
}

module grafana 'grafana/grafana.bicep' = {
  name: 'grafana'
  params: {
    nameSuffix: nameSuffix
    location: location
    monitorWorkspaceName: metrics.outputs.amwWorkspaceName
  }
}

output dcrId string = dcr_aks.outputs.dcrId
output dceId string = dce_aks.outputs.dceId
output logsWorkspaceId string = logs_workspace.outputs.workspaceId
output amaWorkspaceId string = metrics.outputs.amwWorkspaceId

