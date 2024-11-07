targetScope = 'subscription'

param location string
param rgNameApp string
param rgNameNetwork string
param nameSuffix string
param vnetName string

module aks_uai 'uai.bicep' = {
  scope: resourceGroup(rgNameApp)
  name: 'aks-uai'
  params: {
    location: location 
    nameSuffix: nameSuffix
  }
}

module managed_identity 'managed-identity-operator-assignment.bicep' = {
  scope: resourceGroup(rgNameApp)
  name: 'managed-identity-operator-assignment'
  params: {
    principalId: aks_uai.outputs.principalId
  }
}

module role_assignment 'network-contributor-assignment.bicep' = {
  scope: resourceGroup(rgNameNetwork)
  name: 'role-assignment'
  params: {
    principalId: aks_uai.outputs.principalId
    vnetName: vnetName
  }
}

output aksUaiName string = aks_uai.outputs.name
