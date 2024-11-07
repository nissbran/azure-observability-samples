param nameSuffix string
param location string = resourceGroup().location
param logAnalyticsWorkspaceResourceId string
param dataCollectionRuleId string
param dataCollectionEndpointId string
param userAssignedIdentityName string
param vnetName string
param networkResouceGroup string

param agentVMSize string = 'Standard_D4as_v5'
param kubernetesVersion string = '1.30'
param nodeResourceGroup string = 'rg-aks-${nameSuffix}-nodes'
param vnetNodesSubnetName string = 'sn-nodes'

var aksName = 'aks-${nameSuffix}'
var aksNodesSubnetId = resourceId(networkResouceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, vnetNodesSubnetName)

// Existing user assigned identity ------------------------------------------------
resource aks_uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userAssignedIdentityName
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: aksName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aks_uai.id}': {}
    }
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    publicNetworkAccess: 'Enabled'
    enableRBAC: true
    dnsPrefix: aksName
    identityProfile: {
      kubeletidentity: {
        resourceId: aks_uai.id
        clientId: aks_uai.properties.clientId
        objectId: aks_uai.properties.principalId
      }
    }

    networkProfile: {
      networkPolicy: 'azure'
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      loadBalancerSku: 'Standard'
      outboundType: 'loadBalancer'
    }

    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 1
        minCount: 1
        maxCount: 3
        mode: 'System'
        vmSize: agentVMSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        vnetSubnetID: aksNodesSubnetId
        enableAutoScaling: true
        upgradeSettings: {
          maxSurge: '33%'
        } 
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'workpool'
        count: 1
        minCount: 1
        maxCount: 3
        mode: 'User'
        vmSize: agentVMSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        vnetSubnetID: aksNodesSubnetId
        enableAutoScaling: true
        upgradeSettings: {
          maxSurge: '33%'
        }
      }
    ]

    servicePrincipalProfile: {
      clientId: 'msi'
    }
    azureMonitorProfile: {
      metrics: {
        enabled: true
      }
    }
    addonProfiles: {
      azurePolicy: {
        enabled: true
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
          useAADAuth: 'true'
        }
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    nodeResourceGroup: nodeResourceGroup

    autoUpgradeProfile: {
      upgradeChannel: 'stable'
    }
  }
}

resource dcraAks 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  name: 'dcra-${aksName}'
  scope: aks
  properties: {
    dataCollectionRuleId: dataCollectionRuleId
  }
}

resource dcraConfigAks 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  name: 'configurationAccessEndpoint'
  scope: aks
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointId
  }
}

output aksUaiName string = aks_uai.name
output aksName string = aks.name
output aksResourceId string = aks.id
