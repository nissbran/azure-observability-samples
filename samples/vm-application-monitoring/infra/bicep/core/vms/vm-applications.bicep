param location string
param vnetName string
param vmName string
param VmsSubnetName string = 'sn-vms'
param dataCollectionRuleId string
param dataCollectionEndpointId string
param networkResouceGroup string
param monitoringIdentityId string
@secure()
param adminPassword string

resource pip_public 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: 'pip-${vmName}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource vm_nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'nic-${vmName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(networkResouceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, VmsSubnetName)
          }
          publicIPAddress: {
            id: pip_public.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'vm-${vmName}'
  location: location
   identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${monitoringIdentityId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4as_v5'
    }
    osProfile: {
      computerName: 'vm-${vmName}'
      adminUsername: '${vmName}-admin'
      adminPassword: adminPassword
    }
    storageProfile: {

      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-${vmName}'
        caching: 'ReadWrite'
        createOption: 'FromImage' 
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm_nic.id
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

resource dcraVm 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'dcra-${vmName}'
  scope: vm
  properties: {
    dataCollectionRuleId: dataCollectionRuleId
  }
}

resource dcraConfiguration 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'configurationAccessEndpoint'
  scope: vm
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
  }
}

resource amaAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'ama-agent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      authentication: {
        managedIdentity: {
          identifierName: 'mi_res_id'
          identifierValue: monitoringIdentityId
        }
      }
    }
  }
}

resource dependencyAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm
  name: 'dependency-agent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      enableAMA: true
    }
  }
}

output vmIp string = vm_nic.properties.ipConfigurations[0].properties.privateIPAddress
output vmName string = vm.name
