param networkResourceGroup string
param location string = resourceGroup().location

var nameSuffix = 'application'

module logs_workspace 'loganalytics/workspace.bicep' = {
  name: 'logs'
  params: {
    nameSuffix: nameSuffix
    location: location
    networkResourceGroup: networkResourceGroup
  }
}

module table_app_logs 'loganalytics/table-application-json-logs.bicep' = {
  name: 'app_logs_table'
  params: {
    workspaceName: logs_workspace.outputs.workspaceName
    tablePlan: 'Basic'
  }
  dependsOn: [
    logs_workspace
  ]
}

module table_tomcat_logs 'loganalytics/table-tomcat-logs.bicep' = {
  name: 'app'
  params: {
    workspaceName: logs_workspace.outputs.workspaceName
    tablePlan: 'Basic'
  }
  dependsOn: [
    logs_workspace
  ]
}

module dce_app 'dce/dce-application-vm.bicep' = {
  name: 'dce_app'
  params: {
    nameSuffix: nameSuffix
    location: location
    networkResourceGroup: networkResourceGroup
  }
}

module dcr_app 'dcr/dcr-application-vm.bicep' = {
  name: 'dcr_app'
  params: {
    nameSuffix: nameSuffix
    location: location
    dataCollectionEndpointResourceId: dce_app.outputs.dceId
    workspaceResourceId: logs_workspace.outputs.workspaceId
  }
}

module grafana 'grafana/grafana.bicep' = {
  name: 'grafana'
  params: {
    nameSuffix: nameSuffix
    location: location
  }
}

output dcrId string = dcr_app.outputs.dcrId
output dceId string = dce_app.outputs.dceId

// module logs_insights 'loganalytics/workspace.bicep' = {
//   name: la
//   params: {
//     nameSuffix: 'insights'
//   }
// }
