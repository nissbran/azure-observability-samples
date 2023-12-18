targetScope = 'subscription'

param rgNameNetwork string = 'rg-network-demo-app'
param rgNameOp string = 'rg-observability-demo-app'
param rgNameApp string = 'rg-application-demo-app'
param location string

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
    dataCollectionEndpointId: monitoring.outputs.dceId
    dataCollectionRuleId: monitoring.outputs.dcrId
    location: location
    networkResouceGroup: rgNameNetwork 
    vnetName: network.outputs.vnetName
    monitoringIdentityId: identity.outputs.id
  }
}
