param location string
param azureFirewallSubnetId string

resource fw_policy 'Microsoft.Network/firewallPolicies@2023-06-01' = {
  name: 'fw-policies-${location}'
  location: location
  properties: {
    sku: {
      tier: 'Basic'
    }
    threatIntelMode: 'Deny'
    // insights: {
    //   isEnabled: true
    //   retentionDays: 30
    //   logAnalyticsResources: {
    //     defaultWorkspaceId: {
    //       id: laHub.id
    //     }
    //   }
    // }
    threatIntelWhitelist: {
      fqdns: []
      ipAddresses: []
    }
    intrusionDetection: {
      mode: 'Deny'
      configuration: {
        bypassTrafficSettings: []
        signatureOverrides: []
      }
    }
    dnsSettings: {
      servers: []
      enableProxy: true
    }
  }

  resource defaultNetworkRuleCollectionGroup 'ruleCollectionGroups@2023-06-01' = {
    name: 'DefaultNetworkRuleCollectionGroup'
    properties: {
      priority: 200
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          name: 'org-wide-allowed'
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              ruleType: 'NetworkRule'
              name: 'DNS'
              description: 'Allow DNS outbound (for simplicity, adjust as needed)'
              ipProtocols: [
                'UDP'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
              destinationAddresses: [
                '*'
              ]
              destinationIpGroups: []
              destinationFqdns: []
              destinationPorts: [
                '53'
              ]
            }
          ]
        }
      ]
    }
  }

  // Network hub starts out with no allowances for appliction rules
  resource defaultApplicationRuleCollectionGroup 'ruleCollectionGroups@2023-06-01' = {
    name: 'DefaultApplicationRuleCollectionGroup'
    dependsOn: [
      defaultNetworkRuleCollectionGroup
    ]
    properties: {
      priority: 300
      ruleCollections: []
    }
  }
}

resource pipAzureFirewall 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: 'pip-fw-${location}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

// This is the regional Azure Firewall that all regional spoke networks can egress through.
resource firewall 'Microsoft.Network/azureFirewalls@2023-06-01' = {
  name: 'fw-aks-${location}'
  location: location
  dependsOn: [
    // This helps prevent multiple PUT updates happening to the firewall causing a CONFLICT race condition
    // Ref: https://learn.microsoft.com/azure/firewall-manager/quick-firewall-policy
    fw_policy::defaultApplicationRuleCollectionGroup
    fw_policy::defaultNetworkRuleCollectionGroup
  ]
  properties: {
    sku: {
      tier: 'Basic'
      name: 'AZFW_VNet'
    }
    firewallPolicy: {
      id: fw_policy.id
    }
    ipConfigurations: [{
      name: pipAzureFirewall.name
      properties: {
        subnet: {
          id: azureFirewallSubnetId
        }
        publicIPAddress: {
          id: pipAzureFirewall.id
        }
      }
    }]
  }
}
