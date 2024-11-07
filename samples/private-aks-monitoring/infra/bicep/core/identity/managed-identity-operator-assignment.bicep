param principalId string

var managedIdentityOperatorRole = 'f1a07417-d97a-45cb-824c-7a7467783830'

resource role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, managedIdentityOperatorRole)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', managedIdentityOperatorRole)
    principalType: 'ServicePrincipal'
  }
  scope: resourceGroup()
}
