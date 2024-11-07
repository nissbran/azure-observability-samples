param location string = resourceGroup().location
param vnetName string = 'vnet-eastus-aks'
param addressPrefix string = '11.10.0.0/16'
param ipAddressSource string

// Network Security Groups --------------------------------------------
resource vm_nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-vms'
  location: location
  properties: {
    
  }
}

// resource appgw_nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
//   name: 'nsg-appgw'
//   location: location
//   properties: {
//     securityRules: [
//       {
//         name: 'Allow-HTTP'
//         properties: {
//           protocol: '*'
//           sourcePortRange: '*'
//           destinationPortRange: '80'
//           sourceAddressPrefix: ipAddressSource 
//           destinationAddressPrefix: '*'
//           access: 'Allow'
//           priority: 100
//           direction: 'Inbound'
//         }
//       }
//       {
//         name: 'AllowGatewayManagerInbound'
//         properties: {
//           access: 'Allow'
//           destinationAddressPrefix: '*'
//           destinationPortRange: '65200-65535'
//           direction: 'Inbound'
//           priority: 110
//           protocol: 'TCP'
//           sourceAddressPrefix: 'GatewayManager'
//           sourcePortRange: '*'
//         }
//       }
//     ]
//   }
// }

resource apim_nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
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

// Virtual Network -----------------------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
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
          addressPrefix: cidrSubnet(addressPrefix, 24, 0)
          networkSecurityGroup: {
            id: vm_nsg.id
          }
        }
      }
      {
        name: 'sn-private-endpoints'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 1)
        }
      }
      // {
      //   name: 'sn-appgw'
      //   properties: {
      //     addressPrefix: cidrSubnet(addressPrefix, 24, 2)
      //     networkSecurityGroup: {
      //       id: appgw_nsg.id
      //     }
      //   }
      // }
      {
        name: 'sn-apim'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 3)
          networkSecurityGroup: {
            id: apim_nsg.id
          }
        }
      }
      {
        name: 'sn-nodes'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 4)
          privateLinkServiceNetworkPolicies: 'Disabled'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      // {
      //   name: 'AzureBastionSubnet'
      //   properties: {
      //     addressPrefix: cidrSubnet(addressPrefix, 27, 3)
      //     privateEndpointNetworkPolicies: 'Enabled'
      //     privateLinkServiceNetworkPolicies: 'Enabled'
      //   }
      // }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
