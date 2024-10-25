param vnetName string
param location string = resourceGroup().location
param addressPrefix string = '10.10.0.0/22'
//param ipAddressSource string

resource nsg_default 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: 'nsg-default'
  location: location
  properties: {}
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
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
        name: 'sn-private-endpoints'
        properties: {
          networkSecurityGroup: {
            id: nsg_default.id
          }
          addressPrefix: cidrSubnet(addressPrefix, 24, 0)
        }
      }
      {
        name: 'sn-aca'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 1)
          networkSecurityGroup: {
            id: nsg_default.id
          }
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: 'sn-apim'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 2)
          networkSecurityGroup: {
            id: nsg_default.id
          }
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }

  resource apimSubnet 'subnets' existing = {
    name: 'sn-apim'
  }
  resource acaSubnet 'subnets' existing = {
    name: 'sn-aca'
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output apimSubnetId string = vnet::apimSubnet.id
output acaSubnetId string = vnet::acaSubnet.id
