param location string = resourceGroup().location
param name string

// Service Bus ------------------------------------------------
resource sb_ns 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' = {
  name: 'sb${name}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }

  resource topic 'topics' = {
    name: 'bookings'
    properties: {
      enablePartitioning: true
      supportOrdering: true
    }

    resource subscription 'subscriptions' = {
      name: 'booking-processor'
      properties: {
        requiresSession: true
        deadLetteringOnFilterEvaluationExceptions: true
        deadLetteringOnMessageExpiration: true
        maxDeliveryCount: 10
      }
    }
  }

  resource faultybookings 'topics' = {
    name: 'faultybookings'
    properties: {
      enablePartitioning: true
      supportOrdering: true
    }
  }
}

resource sbSharedKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' = {
  name: 'credits'
  parent: sb_ns
  properties: {
    rights: ['Send', 'Listen', 'Manage']
  }
}
