param nameSuffix string
param location string = resourceGroup().location
param logsWorkspaceResourceId string
param monitorWorkspaceResourceId string
param dataCollectionEndpointResourceId string

resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'dcr-aks-${nameSuffix}'
  location: location
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointResourceId
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: [
            'Microsoft-PrometheusMetrics'
          ]
          labelIncludeFilter: {}
        }
      ]
      extensions: [
        {
          extensionName: 'ContainerInsights'
          name: 'ContainerInsightsExtension'
          streams: [
            'Microsoft-ContainerLog'
            'Microsoft-ContainerLogV2'
            'Microsoft-KubeEvents'
            'Microsoft-KubePodInventory'
          ]
          extensionSettings: {
            dataCollectionSettings: {
              interval: '1m'
              namespaceFilteringMode: 'Include'
              namespaces: [
                'frontend'
              ]
              enableContainerLogV2: true
            }
          }
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'destination-log'
          workspaceResourceId: logsWorkspaceResourceId
        }
      ]
      monitoringAccounts: [
        {
          name: 'PrometheusMonitoringAccount'
          accountResourceId: monitorWorkspaceResourceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-ContainerLogV2'
        ]
        destinations: [
          'destination-log'
        ]
        //transformKql: 'source | where PodNamespace == "frontend" or PodNamespace == "backend"'
      }
      {
        streams: [
          'Microsoft-KubeEvents'
          'Microsoft-KubePodInventory'
        ]
        destinations: [
          'destination-log'
        ]
      }
      {
        streams: [
          'Microsoft-PrometheusMetrics'
        ]
        destinations: [
          'PrometheusMonitoringAccount'
        ]
      }
    ]
  }
}

output dcrId string = dcr.id
