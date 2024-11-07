param location string
param vnetName string
param subnetName string = 'sn-appgw'
param appGatewayName string = 'appgw-application-demo'
//param privateFrontendIp string
param vm01Name string
param vm02Name string

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-appgw'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource appgw 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: appGatewayName
  location: location
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-config'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appgw-public-frontend-ip'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backend-api-pool'
        properties: {
          backendAddresses: [
            {
              fqdn: '${vm01Name}.internal.cloudapp.net'
            }
            {
              fqdn: '${vm02Name}.internal.cloudapp.net'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apim-gw-backend-api-httpsetting'
        properties: {
          port: 8080
          protocol: 'Http'
          cookieBasedAffinity: 'Enabled'
          requestTimeout: 120
        }
      }
    ]
    httpListeners: [
      {
        name: 'apigw-public-http-listener'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appgw-public-frontend-ip')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port80')
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'public-routing-apigw'
        properties: {
          priority: 1
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'apigw-public-http-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'backend-api-pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'apim-gw-backend-api-httpsetting')
          }
        }
      }
    ]
  }
}

output appGwUrl string = 'http://${publicIp.properties.ipAddress}'
