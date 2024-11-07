param location string = resourceGroup().location

resource monitoring_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uai-application-monitoring-identity'
  location: location
}

output id string = monitoring_identity.id

