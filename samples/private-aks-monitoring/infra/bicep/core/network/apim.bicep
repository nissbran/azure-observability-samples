param nameSuffix string
param location string
param publisherEmail string
param publisherName string
param vnetName string
param apimSubnetName string = 'sn-apim'
param networkResouceGroup string

resource pip 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-apim-${nameSuffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: 'pip-apim-${nameSuffix}'
    }
  }
}
 
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' =  {
  name: 'apim-${nameSuffix}'
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkConfiguration: {
      subnetResourceId: resourceId(networkResouceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, apimSubnetName)
    }
    virtualNetworkType: 'Internal'
    publicIpAddressId: pip.id
    publicNetworkAccess: 'Enabled'
  }
}

output apimId string = apim.id
 