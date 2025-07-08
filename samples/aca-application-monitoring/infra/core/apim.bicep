param name string
param appinsightsName string
param location string
//param deployApim bool
param publisherEmail string
param publisherName string
param workspaceId string
param apimSubnetId string
@allowed([
  'BasicV2'
  'StandardV2'
])
param skuName string = 'StandardV2'

resource appinsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appinsightsName
}

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' = {
  name: 'apim-${name}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: skuName
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicNetworkAccess: 'Enabled' 
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
  }
}


resource namedValueAppInsightsKey 'Microsoft.ApiManagement/service/namedValues@2024-06-01-preview' = {
  name: 'appInsightsKey'
  parent: apim
  properties: {
    displayName: 'appInsightsKey'
    value: appinsights.properties.InstrumentationKey
    secret: true
  }
}

resource apiManagementServiceAppinsights 'Microsoft.ApiManagement/service/loggers@2024-06-01-preview' = {
  name: 'appinsights-general-logger'
  parent: apim
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: '{{appInsightsKey}}'
    }
    isBuffered: true
    resourceId: appinsights.id
  }
  dependsOn: [
    namedValueAppInsightsKey
  ]
}

resource apiLogsLA 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'api-logs-to-la'
  scope: apim
  properties: {
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
    ]
    logAnalyticsDestinationType: 'Dedicated'
    workspaceId: workspaceId
  }
}

resource healthApi 'Microsoft.ApiManagement/service/apis@2024-06-01-preview' = {
  name: 'api-health'
  parent: apim
  properties: {
    path: 'api-health'
    displayName: 'Health API for to check the health of the deployed APIs'
    protocols: [
      'https'
    ]
  }
}
