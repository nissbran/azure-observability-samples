param nameSuffix string
param location string

resource aks_uai 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uai-aks-${nameSuffix}'
  location: location
}

output Id string = aks_uai.id
output principalId string = aks_uai.properties.principalId
output name string = aks_uai.name


