param location string
param vnetName string
param networkResourceGroup string

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' existing = {
  name: vnetName
  scope: resourceGroup(networkResourceGroup)
}

// NSG Flow Logs -------------------------------------------------
resource flow_logs_storage_account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stoflowlogs${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource flow_logs_workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'logs-network-${location}'
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource network_watcher 'Microsoft.Network/networkWatchers@2024-01-01' = {
  name: 'nw-${location}' 
  location: location
}

module vnetFlowLogs 'vnet-flow-logs.bicep' = {
  name: 'vm-vnet-flow-logs'
  params: {
    networkWatcherName: network_watcher.name
    location: location
    vnetId: vnet.id
    vnetName: vnet.name
    logWorkspaceId: flow_logs_workspace.id
    storageAccountId: flow_logs_storage_account.id
  }
}
