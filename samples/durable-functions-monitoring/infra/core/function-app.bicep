param location string = resourceGroup().location
param name string
param storageName string
param dtsName string
param deploymentStorageContainerName string
param applicationInsightsName string
param userAssignedIdentityId string
param userAssignedIdentityClientId string

@description('Language runtime used by the function app.')
@allowed(['dotnet-isolated', 'python', 'java', 'node', 'powerShell'])
param functionAppRuntime string = 'dotnet-isolated' //Defaults to .NET isolated worker

@description('Target language version used by the function app.')
@allowed(['3.10', '3.11', '7.4', '8.0', '9.0', '10.0', '11', '17', '20'])
param functionAppRuntimeVersion string = '10.0'

@description('The maximum scale-out instance count limit for the app.')
@minValue(10)
@maxValue(1000)
param maximumInstanceCount int = 10

@description('The memory size of instances used by the app.')
@allowed([2048, 4096])
param instanceMemoryMB int = 2048

@description('A unique token used for resource name generation.')
@minLength(3)
param resourceToken string = toLower(uniqueString(subscription().id, location))

// Existing resources
resource storage 'Microsoft.Storage/storageAccounts@2025-06-01' existing = {
  name: storageName
}
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}
resource dts 'Microsoft.DurableTask/schedulers@2025-11-01' existing = {
  name: dtsName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: 'plan-${name}-${resourceToken}'
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2025-03-01' = {
  name: 'func-${name}'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.properties.primaryEndpoints.blob}${deploymentStorageContainerName}'
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: userAssignedIdentityId
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: maximumInstanceCount
        instanceMemoryMB: instanceMemoryMB
      }
      runtime: {
        name: functionAppRuntime
        version: functionAppRuntimeVersion
      }
    }
  }

  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: {
      AzureWebJobsStorage__accountName: storage.name
      AzureWebJobsStorage__credential: 'managedidentity'
      AzureWebJobsStorage__clientId: userAssignedIdentityClientId
      DURABLE_TASK_SCHEDULER_CONNECTION_STRING: 'Endpoint=${dts.properties.endpoint};TaskHub=task-tracking-hub;Authentication=None'
      //APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsights.properties.ConnectionString
      APPLICATIONINSIGHTS_AUTHENTICATION_STRING: 'ClientId=${userAssignedIdentityClientId};Authorization=AAD'
    }
  }
}
