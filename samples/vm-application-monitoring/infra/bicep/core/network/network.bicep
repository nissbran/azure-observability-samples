param vnetName string
param location string = resourceGroup().location
param addressPrefix string = '10.10.0.0/16'
param ipAddressSource string

resource vm_nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-vms'
  location: location
  properties: {}
}

resource appgw_nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-appgw'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: ipAddressSource 
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          direction: 'Inbound'
          priority: 110
          protocol: 'TCP'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
    ]
  }
} 
 
resource apim_nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-apim'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowTagCustom3443Inbound'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowTagCustom6390Inbound'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '6390'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowTagCustom443Outbound'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowTagCustom1433Outbound'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowTagCustom443OutboundAKV'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureKeyVault'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowTagCustom1886443Outbound'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 150
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '1886'
            '443'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowAnyHTTPSInbound'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 160
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'sn-vms'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 1)
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: vm_nsg.id
          }
        }
      }
      {
        name: 'sn-private-endpoints'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 2)
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'sn-appgw'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 3)
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: appgw_nsg.id
          }
        }
      }
      {
        name: 'sn-apim'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 4)
          privateLinkServiceNetworkPolicies: 'Enabled'
          privateEndpointNetworkPolicies: 'Disabled'
          networkSecurityGroup: {
            id: apim_nsg.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 27, 3)
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }

  resource vmSubnet 'subnets' existing = {
    name: 'sn-vms'
  }
}

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
// ---------------------------------------------------------------

resource azure_monitor_private_endpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
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

resource monitor_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
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

resource oms_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
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

resource ods_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
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

resource agentsvc_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
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

resource blob_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
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

resource azure_monitor_dns_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
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

output vnetName string = vnet.name
output vnetId string = vnet.id
output amplsName string = private_link_scope.name
