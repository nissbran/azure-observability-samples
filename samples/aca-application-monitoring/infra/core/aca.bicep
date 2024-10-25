param name string
param location string = resourceGroup().location
param appinsightsName string
param acrName string = 'acr${name}'
param acaEnvName string = 'acaenv${name}'
param acaSubnetId string

resource appinsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appinsightsName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource aca_env 'Microsoft.App/managedEnvironments@2024-02-02-preview' = {
  name: acaEnvName
  location: location
  properties: {
    appInsightsConfiguration: {
      connectionString: appinsights.properties.ConnectionString
    }
    openTelemetryConfiguration: {
      logsConfiguration: {
        destinations: ['appInsights']
      }
      metricsConfiguration: {
        destinations: [] // appInsights not supported yet
      }
      tracesConfiguration: {
        destinations: ['appInsights']
      }
      destinationsConfiguration: {
        otlpConfigurations: []
      }
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: acaSubnetId
    }
    infrastructureResourceGroup: 'rg-aca-${name}-infra'
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

output staticIp string = aca_env.properties.staticIp
output defaultDomain string = aca_env.properties.defaultDomain
