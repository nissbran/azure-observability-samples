param location string = resourceGroup().location
param name string

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string = toLower(uniqueString(subscription().id, location))

var deploymentStorageContainerName = 'app-package-${take(name, 32)}-${take(resourceToken, 7)}'

resource storage 'Microsoft.Storage/storageAccounts@2025-06-01' = {
  name: 'sto${resourceToken}'
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    dnsEndpointType: 'Standard'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
  }
  resource blobServices 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {}
    }
    resource deploymentContainer 'containers' = {
      name: deploymentStorageContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

output storageAccountName string = storage.name
output deploymentStorageContainer string = deploymentStorageContainerName
output storageAccountResourceId string = storage.id
