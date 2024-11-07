param resourceId string
param resourceName string
param plsName string = 'pls-azure-monitor'

resource private_link_scope 'microsoft.insights/privateLinkScopes@2021-07-01-preview' existing = {
  name: plsName
}

resource private_link_scope_workspace 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-07-01-preview' = {
  name: 'pls-${resourceName}'
  parent: private_link_scope
  properties: {
    linkedResourceId: resourceId
  }
}
