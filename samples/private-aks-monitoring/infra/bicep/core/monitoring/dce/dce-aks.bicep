param nameSuffix string
param location string = resourceGroup().location
param networkResourceGroup string
param privateAccess bool

var dceName = 'dce-aks-${nameSuffix}'

resource dce 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: dceName
  location: location
  properties:{
    networkAcls:{
      publicNetworkAccess: privateAccess ? 'Disabled' : 'Enabled'
    }
  }
}

module connectToPls '../connect-to-monitor-pls.bicep' = if (privateAccess) {
  name: 'pls-${dceName}-connection'
  scope: resourceGroup(networkResourceGroup)
  params:{
    resourceId: dce.id
    resourceName: dce.name
  }
}

output dceId string = dce.id
