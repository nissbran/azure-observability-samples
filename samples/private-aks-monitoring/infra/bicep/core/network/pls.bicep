param vnetName string
param location string = resourceGroup().location

// Existing Resources ---------------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

// Private Link Scope ----------------------------------------------
resource private_link_scope 'microsoft.insights/privateLinkScopes@2021-07-01-preview' = {
  name: 'pls-azure-monitor'
  location: 'global'
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'Open'
      queryAccessMode: 'Open'
    }
  }
}

// DNS Zones -----------------------------------------------------
resource monitor_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.monitor.azure.com'
  location: 'global'
}

resource oms_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.oms.opinsights.azure.com'
  location: 'global'
}

resource ods_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.ods.opinsights.azure.com'
  location: 'global'
}

resource agentsvc_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.agentsvc.azure-automation.net'
  location: 'global'
}

resource blob_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  #disable-next-line no-hardcoded-env-urls
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

// Private endpoint for azure monitor ----------------------------
resource azure_monitor_private_endpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: 'pe-monitor-hub'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'sn-private-endpoints')
    }
    customNetworkInterfaceName: 'nic-pe-monitor-scope'
    privateLinkServiceConnections: [
      {
        name: 'pe-monitor-connection'
        properties: {
          privateLinkServiceId: private_link_scope.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
}

// DNS links to private DNS zones --------------------------------
resource monitor_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'monitor_dns_link_to_hub'
  parent: monitor_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource oms_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'oms_dns_link_to_hub'
  parent: oms_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource ods_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'ods_dns_link_to_hub'
  parent: ods_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource agentsvc_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'agentsvc_dns_link_to_hub'
  parent: agentsvc_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource blob_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'blob_dns_link_to_hub'
  parent: blob_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// DNS groups -----------------------------------------------------
resource azure_monitor_dns_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  parent: azure_monitor_private_endpoint
  name: 'monitor-pe-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-monitor-azure-com'
        properties: {
          privateDnsZoneId: monitor_private_dns_zone.id
        }
      }
      {
        name: 'privatelink-oms-opinsights-azure-com'
        properties: {
          privateDnsZoneId: oms_private_dns_zone.id
        }
      }
      {
        name: 'privatelink-ods-opinsights-azure-com'
        properties: {
          privateDnsZoneId: ods_private_dns_zone.id
        }
      }
      {
        name: 'privatelink-agentsvc-azure-automation-net'
        properties: {
          privateDnsZoneId: agentsvc_private_dns_zone.id
        }
      }
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: blob_private_dns_zone.id
        }
      }
    ]
  }
}

output amplsName string = private_link_scope.name
