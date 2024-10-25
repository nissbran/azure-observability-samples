param vnetId string
param staticIp string
param defaultDomain string

resource internal_dns_zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: defaultDomain
  location: 'global'
}

resource a_record 'Microsoft.Network/privateDnsZones/A@2024-06-01' = {
  name: '*'
  parent: internal_dns_zone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: staticIp
      }
    ]
  }
}

resource internal_dns_link_to_vnet 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'internal_dns_link_to_hub'
  parent: internal_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
