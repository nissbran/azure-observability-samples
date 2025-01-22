param nameSuffix string
param location string = resourceGroup().location
param logsWorkspaceResourceId string
param dataCollectionEndpointResourceId string

resource dcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-metrics-${nameSuffix}'
  location: location
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointResourceId
    dataSources: {
      platformTelemetry: [
        {
          name: 'platformTelemetry'
          streams: [
            'Microsoft.Compute/virtualMachineScaleSets:Metrics-Group-All'
            'Microsoft.ContainerService/managedClusters:Metrics-Group-All'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'destination-metrics'
          workspaceResourceId: logsWorkspaceResourceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
            'Microsoft.ContainerService/managedClusters:Metrics-Group-All'
        ]
        destinations: [
          'destination-metrics'
        ]
        transformKql: 'source | where MetricName != "kube_pod_status_phase"'
      }
      {
        streams: [
            'Microsoft.Compute/virtualMachineScaleSets:Metrics-Group-All'
        ]
        destinations: [
          'destination-metrics'
        ]
      }
    ]
  }
}

output dcrId string = dcr.id
