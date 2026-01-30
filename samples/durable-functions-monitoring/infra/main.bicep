targetScope = 'subscription'

param appName string = 'funcmondemo'
param rgName string = 'rg-${appName}-app'
param location string

param sqlAdminLogin string = 'adminlogin'
@secure()
param sqlAdminPassword string

resource rg_app 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

module monitoring 'core/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg_app
  params: {
    location: rg_app.location
    name: appName
  }
}

// module sqlserver 'core/sqlserver.bicep' = {
//   name: 'sqlserver'
//   scope: rg_app
//   params: {
//     serverName: 'sql${appName}'
//     administratorLogin: sqlAdminLogin
//     administratorLoginPassword: sqlAdminPassword
//   }
// }

module storage 'core/storage.bicep' = {
  name: 'storage'
  scope: rg_app
  params: {
    location: rg_app.location
    name: appName
  }
}

module dts 'core/dts.bicep' = {
  name: 'dts'
  scope: rg_app
  params: {
    location: rg_app.location
    name: appName
  }
}

module funcIdentity 'core/function-managed-identity.bicep' = {
  name: 'function-managed-identity'
  scope: rg_app
  params: {
    location: rg_app.location
    name: appName
    storageAccountName: storage.outputs.storageAccountName
    applicationInsightsName: monitoring.outputs.appinsightsName
  }
}

module functionApp 'core/function-app.bicep' = {
  name: 'function-app'
  scope: rg_app
  params: {
    location: rg_app.location
    name: appName
    applicationInsightsName: monitoring.outputs.appinsightsName
    dtsName: dts.outputs.dtsName
    storageName: storage.outputs.storageAccountName
    userAssignedIdentityId: funcIdentity.outputs.userAssignedIdentityId
    deploymentStorageContainerName: storage.outputs.deploymentStorageContainer
    userAssignedIdentityClientId: funcIdentity.outputs.userAssignedIdentityClientId
  }
}
