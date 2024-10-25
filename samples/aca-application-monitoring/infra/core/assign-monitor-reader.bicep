targetScope = 'subscription'
param grafanaName string
param grafanaPrincipalId string

var monitoringReader = resourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05')

resource grafana_monitor_reader_rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: subscription()
  name: guid(grafanaName, monitoringReader, subscription().id)
  properties: {
    roleDefinitionId: monitoringReader
    principalId: grafanaPrincipalId
    principalType: 'ServicePrincipal'
  }
}
