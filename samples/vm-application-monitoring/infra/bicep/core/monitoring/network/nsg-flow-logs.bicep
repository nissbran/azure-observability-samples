param location string
param nsgId string
param nsgName string
param networkWatcherName string
param logWorkspaceId string
param storageAccountId string

param retentionDays int = 1

resource network_watcher 'Microsoft.Network/networkWatchers@2024-01-01' existing = {
  name: networkWatcherName
}

resource nsg_flow_logs 'Microsoft.Network/networkWatchers/flowLogs@2024-01-01' = {
  name: 'nsg-flowlogs-${nsgName}'
  parent: network_watcher
  location: location
  properties: {
    targetResourceId: nsgId
    storageId: storageAccountId
    format: {
      type: 'JSON'
      version: 2
    }
    enabled: true
    retentionPolicy: {
      days: retentionDays
      enabled: true
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        trafficAnalyticsInterval: 60
        workspaceRegion: location
        workspaceResourceId: logWorkspaceId
      }
    }
  }
}
