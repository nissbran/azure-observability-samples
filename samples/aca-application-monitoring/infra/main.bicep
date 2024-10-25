targetScope = 'subscription'

param appName string = 'appdemo00112'
param rgNameNetwork string = 'rg-${appName}-network'
param rgNameApp string = 'rg-${appName}-app'
param location string
param publisherEmail string
param publisherName string

param sqlAdminLogin string = 'adminlogin'
@secure()
param sqlAdminPassword string

resource rg_network 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNameNetwork
  location: location
}

resource rg_app 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgNameApp
  location: location
}

module network 'core/network.bicep' = {
  name: 'network'
  scope: rg_network
  params: {
    vnetName: 'vnet-${appName}'
  }
}

module monitoring 'core/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg_app
  params: {
    location: rg_app.location
    name: appName
  }
}

module sqlserver 'core/sqlserver.bicep' = {
  name: 'sqlserver'
  scope: rg_app
  params: {
    serverName: 'sql${appName}'
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
  }
}

module servicebus 'core/servicebus.bicep' = {
  name: 'servicebus'
  scope: rg_app
  params: {
    location: rg_app.location
    name: appName
  }
}

module aca_env 'core/aca.bicep' = {
  name: 'aca'
  scope: rg_app
  params: {
    name: appName
    location: rg_app.location
    appinsightsName: monitoring.outputs.appinsightsName
    acaSubnetId: network.outputs.acaSubnetId
  }
}

module apim 'core/apim.bicep' = {
  name: 'apim'
  scope: rg_app
  params: {
    name: appName
    location: rg_app.location
    publisherEmail: publisherEmail
    publisherName: publisherName
    apimSubnetId: network.outputs.apimSubnetId
    appinsightsName: monitoring.outputs.appinsightsName
    workspaceId: monitoring.outputs.workspaceId
  }
}

module acaDnsConfig 'core/internal-dns.bicep' = {
  scope: rg_network
  name: 'acaDnsConfig'
  params: {
    defaultDomain: aca_env.outputs.defaultDomain
    staticIp: aca_env.outputs.staticIp
    vnetId: network.outputs.vnetId
  }
}
