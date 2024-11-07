targetScope = 'subscription'

param rgNameNetwork string = 'rg-network-aks-app'
param rgNameOp string = 'rg-observability-aks-app'
param rgNameApp string = 'rg-application-aks-app'
param ipAddressSource string
param location string
param nameSuffix string
param publisherEmail string
param publisherName string
@description('Email addresses to which the notifications should be sent. Should be specified as an array of strings, for example, ["user1@contoso.com", "user2@contoso.com"].')
param alertEmailAddress array
param deployAlerts bool = false
param deployApim bool = false

resource rg_network 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNameNetwork
  location: location
}

resource rg_observability 'Microsoft.Resources/resourceGroups@2024-03-01' = {
   name: rgNameOp
   location: location
}

resource rg_application 'Microsoft.Resources/resourceGroups@2024-03-01' = {
   name: rgNameApp
   location: location
}

module network 'core/network/network.bicep' = {
  name: 'network'
  scope: rg_network
  params: {
    vnetName: 'vnet-private-aks-app'
    ipAddressSource: ipAddressSource
    location: location
  }
}

module monitoring 'core/monitoring/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg_observability
  params: {
    vnetName: network.outputs.vnetName
    location: location
    networkResourceGroup: rgNameNetwork
    privateAccess: false
    deployNetworkWatcher: false
    nameSuffix: nameSuffix
  }
}

module identity 'core/identity/aks-identity.bicep' = {
  name: 'identity'
  params: {
    location: location
    rgNameApp: rgNameApp
    rgNameNetwork: rgNameNetwork
    nameSuffix: nameSuffix
    vnetName: network.outputs.vnetName
  }
}

module aks 'core/aks/cluster.bicep' = {
  name: 'aks'
  scope: rg_application
  params: {
    userAssignedIdentityName: identity.outputs.aksUaiName
    location: location
    dataCollectionRuleId: monitoring.outputs.dcrId
    dataCollectionEndpointId: monitoring.outputs.dceId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logsWorkspaceId
    nameSuffix: nameSuffix
    vnetName: network.outputs.vnetName
    networkResouceGroup: rgNameNetwork
  }
}

module apim 'core/network/apim.bicep' = if(deployApim) {
  name: 'apim'
  scope: rg_application
  params: {
    location: location
    vnetName: network.outputs.vnetName
    networkResouceGroup: rgNameNetwork
    nameSuffix: nameSuffix
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

module prom_rule_groups 'core/monitoring/metrics/rule-groups.bicep' = {
  scope: rg_observability
  name: 'prom_rule_groups'
  params: {
    azureMonitorWorkspaceResourceId: monitoring.outputs.amaWorkspaceId  
    clusterName: aks.outputs.aksName
    clusterResourceId: aks.outputs.aksResourceId
    location: location
  }
}

module alerts 'core/monitoring/alerts/alerts.bicep' = if (deployAlerts) {
  scope: rg_observability
  name: 'cluster_alerts'
  params: {
    aksResourceId: aks.outputs.aksResourceId
    emailAddress: alertEmailAddress
    location: location
    monitorWorkspaceId: monitoring.outputs.amaWorkspaceId
    apimResourceId: apim.outputs.apimId
  }
}
