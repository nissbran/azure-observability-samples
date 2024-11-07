param location string
param vnetHubName string
param hubVmsSubnetName string = 'sn-vms'
// param vmMonitoringIdentityId string
param adminUsername string = 'jumpbox-admin'
@secure()
param adminPassword string

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-bastion'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: 'bastion-hub'
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetHubName, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: 'pip-bastion-config'
      }
    ]
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'nic-jumpbox'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetHubName, hubVmsSubnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'vm-jumpbox'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4as_v5'
    }
    osProfile: {
      computerName: 'vm-jumpbox'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    securityProfile:{
      
    }
    storageProfile: {

      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: 'disk-jumpbox-os-01'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}
