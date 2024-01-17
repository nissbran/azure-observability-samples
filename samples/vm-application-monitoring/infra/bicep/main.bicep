targetScope = 'subscription'

param rgNameNetwork string = 'rg-network-demo-app'
param rgNameOp string = 'rg-observability-demo-app'
param rgNameApp string = 'rg-application-demo-app'
param ipAddressSource string
param location string
@secure()
param vmPassword string
@description('Email addresses to which the notifications should be sent. Should be specified as an array of strings, for example, ["user1@contoso.com", "user2@contoso.com"].')
param emailAddress array

resource rg_network 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgNameNetwork
  location: location
}

resource rg_observability 'Microsoft.Resources/resourceGroups@2022-09-01' = {
   name: rgNameOp
   location: location
}
resource rg_application 'Microsoft.Resources/resourceGroups@2022-09-01' = {
   name: rgNameApp
   location: location
}

module network 'core/network/network.bicep' = {
  name: 'network'
  scope: rg_network
  params: {
    vnetName: 'vnet-demo-app'
    ipAddressSource: ipAddressSource
    location: location
  }
}

module monitoring 'core/monitoring/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg_observability
  params: {
    location: location
    networkResourceGroup: rgNameNetwork
  }
}

module identity 'core/monitoring/identity/monitoring-uai.bicep' = {
  name: 'identity'
  scope: rg_observability
  params: {
    location: location
  }
}

module app_vm_01 'core/vms/vm-applications.bicep' = {
  scope: rg_application
  name: 'vm-applications-01'
  params: {
    vmName: 'app-01'
    adminPassword: vmPassword
    dataCollectionEndpointId: monitoring.outputs.dceId
    dataCollectionRuleId: monitoring.outputs.dcrId
    securityDataCollectionRuleId: monitoring.outputs.secDcrId
    location: location
    networkResouceGroup: rgNameNetwork 
    vnetName: network.outputs.vnetName
    monitoringIdentityId: identity.outputs.id
  }
}

module app_vm_02 'core/vms/vm-applications.bicep' = {
  scope: rg_application
  name: 'vm-applications-02'
  params: {
    vmName: 'app-02'
    adminPassword: vmPassword
    dataCollectionEndpointId: monitoring.outputs.dceId
    dataCollectionRuleId: monitoring.outputs.dcrId
    securityDataCollectionRuleId: monitoring.outputs.secDcrId
    location: location
    networkResouceGroup: rgNameNetwork 
    vnetName: network.outputs.vnetName
    monitoringIdentityId: identity.outputs.id
  }
}

module app_gw 'core/network/appgw.bicep' = {
  scope: rg_network
  name: 'appgw'
  params: {
    location: location
    vm01Name: app_vm_01.outputs.vmName
    vm02Name: app_vm_02.outputs.vmName
    vnetName: network.outputs.vnetName
  }
}

module alerts 'core/monitoring/alerts/alerts.bicep' = {
  name: 'alerts'
  scope: rg_observability
  params: {
    appgatewayId: app_gw.outputs.appGwId
    applogsWorkspaceId: monitoring.outputs.appLogsWorkspaceId
    emailAddress: emailAddress
    location: location
  }
}
