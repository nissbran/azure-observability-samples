param name string
param location string = resourceGroup().location
param sqlAdminLogin string = 'adminlogin'
@secure()
param sqlAdminPassword string

var creditApiVersion = '1.8'
var bookingProcessorVersion = '1.6'

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var sbDataOwnerRole = resourceId('Microsoft.Authorization/roleDefinitions', '090c5cfd-751d-490a-894a-3ce6f1109419')

// Existing resources ---------------------------------------------------------
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: 'acr${name}'
}

resource aca_env 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: 'acaenv${name}'
}

resource sb_ns 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: 'sb${name}'
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: 'sql${name}'
}

resource creditDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = {
  name: 'credit-db'
  parent: sqlServer
}

resource bookingDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' existing = {
  name: 'booking-db'
  parent: sqlServer
}

resource sbSharedKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' existing = {
  name: 'credits'
  parent: sb_ns
}

resource appinsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'appinsights${name}'
}

// Credit api -----------------------------------------------------------------
resource credit_api 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'credit-api'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: aca_env.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 8080
      }
      secrets: [
        {
          name: 'registry-password'
          value: acr.listCredentials().passwords[0].value
        }
        {
          name: 'db-connection-string'
          value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${creditDb.name};User Id=${sqlAdminLogin}@${sqlServer.properties.fullyQualifiedDomainName};Password=${sqlAdminPassword};'
        }
        {
          name: 'appinsights-connection-string'
          value: appinsights.properties.ConnectionString
        }
      ]
      registries: [
        {
          username: acr.name
          passwordSecretRef: 'registry-password'
          server: acr.properties.loginServer
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${acr.name}.azurecr.io/credits/credit-api:${creditApiVersion}'
          name: 'credit-api'
          env: [
            {
              name: 'OTEL_SERVICE_NAME'
              value: 'credit-api'
            }
            {
              name: 'USE_CONSOLE_LOG_OUTPUT'
              value: 'true'
            }
            {
              name: 'USE_SERILOG_FOR_OTEL'
              value: 'true'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING' 
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'ConnectionStrings__credit-db' 
              secretRef: 'db-connection-string'
            }
            {
              name: 'ConnectionStrings__messaging' 
              value: '${sb_ns.name}.servicebus.windows.net'
            }
          ]
          resources:{
            cpu: json('.25')
            memory: '.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
        rules: []
      }
    }
  }
}

resource credit_api_pull_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, credit_api.name, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalId: credit_api.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource credit_api_sb_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sb_ns.id, credit_api.name, sbDataOwnerRole)
  properties: {
    roleDefinitionId: sbDataOwnerRole
    principalId: credit_api.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Booking processor ----------------------------------------------------------
resource booking_processor 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'booking-processor'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: aca_env.id
    configuration: {
      activeRevisionsMode: 'single'
      secrets: [
        {
          name: 'sb-connection-string'
          value: sbSharedKey.listKeys().primaryConnectionString
        }
        {
          name: 'registry-password'
          value: acr.listCredentials().passwords[0].value
        }
        {
          name: 'appinsights-connection-string'
          value: appinsights.properties.ConnectionString
        }
        {
          name: 'db-connection-string'
          value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${bookingDb.name};User Id=${sqlAdminLogin}@${sqlServer.properties.fullyQualifiedDomainName};Password=${sqlAdminPassword};'
        }
      ]
      registries: [
        {
          username: acr.name
          passwordSecretRef: 'registry-password'
          server: acr.properties.loginServer
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${acr.name}.azurecr.io/credits/booking-processor:${bookingProcessorVersion}'
          name: 'booking-processor'
          env: [
            {
              name: 'OTEL_SERVICE_NAME'
              value: 'booking-processor'
            }
            {
              name: 'USE_CONSOLE_LOG_OUTPUT'
              value: 'true'
            }
            {
              name: 'USE_SERILOG_FOR_OTEL'
              value: 'true'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING' 
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'ConnectionStrings__booking-db' 
              secretRef: 'db-connection-string'
            }
            {
              name: 'ConnectionStrings__messaging' 
              value: '${sb_ns.name}.servicebus.windows.net'
            }
          ]
          resources:{
            cpu: json('.25')
            memory: '.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'sb-scale-rule'
            custom: {
              type: 'azure-servicebus'
              auth: [
                {
                  secretRef: 'sb-connection-string'
                  triggerParameter: 'connection'
                }
              ]
              metadata: {
                topicName: 'bookings'
                subscriptionName: 'booking-processor'
                queueLength: '64'
              }
            }
          }
        ]
      }
    }
  }
}

resource booking_processor_pull_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, booking_processor.name, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalId: booking_processor.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource booking_processor_sb_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sb_ns.id, booking_processor.name, sbDataOwnerRole)
  properties: {
    roleDefinitionId: sbDataOwnerRole
    principalId: booking_processor.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure API Management -------------------------------------------------------
resource apim 'Microsoft.ApiManagement/service@2023-09-01-preview' existing = {
  name: 'apim-${name}'
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-09-01-preview' existing = {
  name: 'appinsights-general-logger'
  parent: apim
}

resource creditApiBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'credit-api-aca-backend'
  parent: apim
  properties: {
    description: 'credit-api'
    url: 'https://${credit_api.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

resource creditApimApi 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  name: 'credit-api'
  parent: apim
  properties: {
    displayName: 'Credit API'
    path: 'credit-api'
    apiType: 'http'
    format: 'openapi+json'
    protocols: [
      'https'
    ]
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    subscriptionRequired: true
    value: loadTextContent('../src/dotnet/credit-api/Swagger/api-spec.json')
  }
}

resource defaultCreditApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-09-01-preview' = {
  name: 'policy'
  parent: creditApimApi
  properties: {
    format: 'rawxml'
    value: loadTextContent('apim-config/credit-api-policy.cshtml')
  }
  dependsOn: [
    creditApiBackend
  ]
}

resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2023-09-01-preview' = {
  name: 'credit-api-subscription'
  parent: apim
  properties: {
    allowTracing: true
    displayName: 'Credit API Subscription'
    scope: '/apis/${creditApimApi.id}'
    state: 'active'
  }
}

// Credit API Facade ----------------------------------------------------------
resource creditApiFacade 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  name: 'credit-api-facade'
  parent: apim
  properties: {
    displayName: 'Credit API Facade'
    path: 'credits'
    apiType: 'http'
    format: 'openapi'
    protocols: [
      'https'
    ]
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    apiRevision: 'initial'
    value: loadTextContent('apim-config/credit-facade.yaml')
  }
}

resource apimFacadeSubscription 'Microsoft.ApiManagement/service/subscriptions@2023-09-01-preview' = {
  name: 'credit-api-facade-subscription'
  parent: apim
  properties: {
    allowTracing: true
    displayName: 'Credit Facade API Subscription'
    scope: '/apis/${creditApiFacade.id}'
    state: 'active'
  }
}

resource defaultCreditFacadeApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-09-01-preview' = {
  name: 'policy'
  parent: creditApiFacade
  properties: {
    format: 'rawxml'
    value: loadTextContent('apim-config/credit-api-facade-policy.cshtml')
  }
  dependsOn: [
    creditApiBackend
  ]
}

resource facadeApiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01' = if (!empty(apimLogger.name)) {
  name: 'applicationinsights'
  parent: creditApiFacade
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    logClientIp: true
    loggerId: apimLogger.id
    metrics: true
    verbosity: 'information'
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
  }
}
