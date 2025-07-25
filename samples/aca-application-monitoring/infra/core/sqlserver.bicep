@description('The name of the SQL logical server.')
param serverName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The administrator username of the SQL logical server.')
param administratorLogin string

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource creditDb 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: 'credit-db'
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1 // 1 vCore
  }
  properties: {
    autoPauseDelay: 60 // Auto-pause after 60 minutes of inactivity
  }
}

resource bookingDb 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: 'booking-db'
  location: location
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1 // 1 vCore
  }
  properties: {
    autoPauseDelay: 60 // Auto-pause after 60 minutes of inactivity
  }
}

