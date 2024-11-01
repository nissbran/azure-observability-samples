param name string
param location string = resourceGroup().location
param sqlAdminLogin string = 'adminlogin'
@secure()
param sqlAdminPassword string

param creditApiVersion string
param bookingProcessorVersion string
param bookingApiVersion string

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

// Credit api 1 ---------------------------------------------------------------
resource credit_api_1 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'credit-api-1'
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
          name: 'credit-api-1'
          env: [
            {
              name: 'OTEL_SERVICE_NAME'
              value: 'credit-api-1'
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
          resources: {
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

resource credit_api_pull_assignment_1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, credit_api_1.name, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalId: credit_api_1.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource credit_api_sb_assignment_1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sb_ns.id, credit_api_1.name, sbDataOwnerRole)
  properties: {
    roleDefinitionId: sbDataOwnerRole
    principalId: credit_api_1.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Credit api 2 ---------------------------------------------------------------
resource credit_api_2 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'credit-api-2'
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
          name: 'credit-api-2'
          env: [
            {
              name: 'OTEL_SERVICE_NAME'
              value: 'credit-api-2'
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
          resources: {
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

resource credit_api_pull_assignment_2 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, credit_api_2.name, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalId: credit_api_2.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource credit_api_sb_assignment_2 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sb_ns.id, credit_api_2.name, sbDataOwnerRole)
  properties: {
    roleDefinitionId: sbDataOwnerRole
    principalId: credit_api_2.identity.principalId
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
          resources: {
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

// Booking api -----------------------------------------------------------------
resource booking_api 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'booking-api'
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
          value: 'Data Source=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${bookingDb.name};User Id=${sqlAdminLogin}@${sqlServer.properties.fullyQualifiedDomainName};Password=${sqlAdminPassword};'
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
          image: '${acr.name}.azurecr.io/credits/booking-api:${bookingApiVersion}'
          name: 'booking-api'
          env: [
            {
              name: 'OTEL_SERVICE_NAME'
              value: 'booking-api'
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
              name: 'Authority'
              value: 'https://login.microsoftonline.com/${subscription().tenantId}'
            }
            {
              name: 'Audience'
              value: 'api://booking-api'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'ConnectionStrings__booking-db'
              secretRef: 'db-connection-string'
            }
          ]
          resources: {
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

resource booking_api_pull_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, booking_api.name, acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalId: booking_api.identity.principalId
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

resource creditApiBackend1 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'credit-api-aca-backend1'
  parent: apim
  properties: {
    description: 'credit-api'
    url: 'https://${credit_api_1.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 3
            errorReasons: [
              'Server errors'
            ]
            interval: 'PT1M'
            statusCodeRanges: [
              {
                min: 429
                max: 429
              }
            ]
          }
          name: 'credit-api-circuit-breaker'
          tripDuration: 'PT1M'
          acceptRetryAfter: true // respects the Retry-After header
        }
      ]
    }
  }
}

resource creditApiBackend2 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'credit-api-aca-backend2'
  parent: apim
  properties: {
    description: 'credit-api'
    url: 'https://${credit_api_2.properties.configuration.ingress.fqdn}'
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
    circuitBreaker: {
      rules: [
        {
          failureCondition: {
            count: 1
            errorReasons: [
              'Server errors'
            ]
            interval: 'PT1M'
            statusCodeRanges: [
              {
                min: 429
                max: 429
              }
            ]
          }
          name: 'credit-api-circuit-breaker'
          tripDuration: 'PT1M'
          acceptRetryAfter: false // respects the Retry-After header
        }
      ]
    }
  }
}

resource creditApiBackendPool 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'credit-api-aca-backend-pool'
  parent: apim
  properties: {
    type: 'Pool'
    description: 'credit api backend pool'
    pool: {
      services:[
        {
          id: creditApiBackend1.id
          priority: 1
          weight: 50
        }
        {
          id: creditApiBackend2.id
          priority: 1
          weight: 50
        }
      ]
    }
  }
}

resource bookingApiBackend 'Microsoft.ApiManagement/service/backends@2023-09-01-preview' = {
  name: 'booking-api-aca-backend'
  parent: apim
  properties: {
    description: 'booking-api'
    url: 'https://${booking_api.properties.configuration.ingress.fqdn}'
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
    value: loadTextContent('../src/dotnet/credit-api/Swagger/CreditApi.json')
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
    creditApiBackendPool
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

resource bookingOperation 'Microsoft.ApiManagement/service/apis/operations@2023-09-01-preview' = {
  name: 'GetBookings'
  parent: creditApiFacade
  properties: {
    displayName: 'GetBookings'
    method: 'GET'
    urlTemplate: '/{id}/bookings'
    templateParameters: [
      {
        name: 'id'
        type: 'string'
        required: true
      }
    ]
    request: {}
    // responses: [
    //   {
    //     statusCode: 200
    //     description: 'Success'
    //     representations: [
    //       {
    //         contentType: 'application/json'
    //         examples: [
    //           {
    //             name: 'example'
    //             value: loadTextContent('apim-config/booking-example.json')
    //           }
    //         ]
    //       }
    //     ]
    //   }
    // ]
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
    creditApiBackendPool
  ]
}

resource creditFacadeBookingsApiPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-09-01-preview' = {
  name: 'policy'
  parent: bookingOperation
  properties: {
    format: 'rawxml'
    value: loadTextContent('apim-config/credit-api-facade-bookings-policy.cshtml')
  }
  dependsOn: [
    bookingApiBackend
  ]
}

resource facadeApiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01' = {
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

// Health check ----------------------------------------------------------------
resource creditApi1HealthCheckUrl 'Microsoft.ApiManagement/service/namedValues@2023-09-01-preview' = {
  name: 'credit-api-1-health-check-url'
  parent: apim
  properties: {
    displayName: 'credit-api-1-health-check-url'
    secret: false
    value: 'https://${credit_api_1.properties.configuration.ingress.fqdn}/healthz'
  }
}

resource creditApi2HealthCheckUrl 'Microsoft.ApiManagement/service/namedValues@2023-09-01-preview' = {
  name: 'credit-api-2-health-check-url'
  parent: apim
  properties: {
    displayName: 'credit-api-2-health-check-url'
    secret: false
    value: 'https://${credit_api_2.properties.configuration.ingress.fqdn}/healthz'
  }
}
