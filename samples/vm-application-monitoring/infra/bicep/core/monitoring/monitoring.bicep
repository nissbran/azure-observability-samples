param networkResourceGroup string
param location string = resourceGroup().location

var nameSuffix = 'application'

module logs_workspace 'loganalytics/application-workspace.bicep' = {
  name: 'logs'
  params: {
    nameSuffix: nameSuffix
    location: location
    networkResourceGroup: networkResourceGroup
  }
}

module logs_security_workspace 'loganalytics/security-workspace.bicep' = {
  name: 'sec_logs'
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
    tablePlan: 'Analytics'
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

module table_event_logs 'loganalytics/table-event-logs.bicep' = {
  name: 'event_logs_table'
  params: {
    workspaceName: logs_security_workspace.outputs.workspaceName
    tablePlan: 'Auxiliary'
  }
  dependsOn: [
    logs_security_workspace
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
  dependsOn: [
    table_app_logs
  ]
}

module dcr_vm_insights 'dcr/dcr-vm-insights.bicep' = {
  name: 'dcr_vm_insights'
  params: {
    nameSuffix: nameSuffix
    location: location
  }
}

module dcr_security 'dcr/dcr-security-vm.bicep' = {
  name: 'dcr_security'
  params: {
    nameSuffix: nameSuffix
    location: location
    dataCollectionEndpointResourceId: dce_app.outputs.dceId
    workspaceResourceId: logs_security_workspace.outputs.workspaceId
  }
  dependsOn: [
    table_event_logs
  ]
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
output secDcrId string = dcr_security.outputs.dcrId
output appLogsWorkspaceId string = logs_workspace.outputs.workspaceId

