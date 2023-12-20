param location string
param nameSuffix string

resource grafana 'Microsoft.Dashboard/grafana@2023-09-01' = {
  name: 'grafana${nameSuffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    grafanaMajorVersion: '10'
    publicNetworkAccess: 'Enabled'
  } 
}

module monitorRbacAssignment 'assign-monitor-reader.bicep' = {
  scope: subscription()
  name: 'grafana-monitor-reader'
  params: {
    grafanaName: grafana.name
    grafanaPrincipalId: grafana.identity.principalId
  }
}

