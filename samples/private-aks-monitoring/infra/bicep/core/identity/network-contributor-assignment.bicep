param principalId string
param vnetName string

var networkContributorRole = '4d97b98b-1d4f-4787-a291-c67834d212e7'

resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
}

resource role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, principalId, networkContributorRole)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', networkContributorRole)
    principalType: 'ServicePrincipal'
  }
  scope: spokeVnet
}
