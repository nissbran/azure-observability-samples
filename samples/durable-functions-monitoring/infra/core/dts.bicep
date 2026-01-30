param location string = resourceGroup().location
param name string

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string = toLower(uniqueString(subscription().id, location))

resource dts 'Microsoft.DurableTask/schedulers@2025-11-01' = {
  location: location
  name: 'dts-${name}-${resourceToken}'
  properties: {
    ipAllowlist: [
      '0.0.0.0/0'
    ]
    sku: {
      name: 'Consumption'
    }
  }
}

resource dtsStorage 'Microsoft.DurableTask/schedulers/taskHubs@2025-11-01' = {
  parent: dts
  name: 'task-tracking-hub'
}

output dtsName string = dts.name
output hubName string = dtsStorage.name
