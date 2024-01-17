param nameSuffix string
param location string = resourceGroup().location
param workspaceResourceId string
param dataCollectionEndpointResourceId string

resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'dcr-app-win-vm-${nameSuffix}'
  location: location
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointResourceId
    description: 'DCR for Application Vms'
    streamDeclarations: {
      'Custom-Tomcat-Deamon-LogFileFormat': {
        columns: [
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }
          {
            name: 'RawData'
            type: 'string'
          }
          {
            name: 'FilePath'
            type: 'string'
          }
        ]
      }
      'Custom-Json-LogFileFormat': {
        columns: [
          {
            name: 'TimeGenerated'
            type: 'datetime'
          }
          {
            name: 'RawData'
            type: 'string'
          }
          {
            name: 'FilePath'
            type: 'string'
          }
        ]
      }
    }
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
      extensions: [
        {
          streams: [
            'Microsoft-ServiceMap'
          ]
          extensionName: 'DependencyAgent'
          extensionSettings: {}
          name: 'DependencyAgentDataSource'
        }
      ]
      windowsEventLogs: [
        {
          name: 'WindowsEventLogsDataSource'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            //Collect all Critical, Error, Warning, and Information events from the System event log except for Event ID = 6 (Driver loaded)
            'System!*[System[(Level=1 or Level=2 or Level=3) and (EventID != 6)]]'
          ]
        }
      ]
      logFiles: [
        {
          name: 'TomcatLogFiles'
          format: 'text'
          filePatterns: [
            'C:\\Program Files\\Apache Software Foundation\\Tomcat 10.1\\logs\\*.log'
          ]
          settings: {
            text: {
              //recordStartTimestampFormat: 'YYYY-MM-DD HH:MM:SS' // 2023-12-08 13:00:26
              recordStartTimestampFormat: 'ISO 8601'
            }
          }
          streams: [
            'Custom-Tomcat-Deamon-LogFileFormat'
          ]
        }
        {
          name: 'JsonLogFiles'
          format: 'json'
          filePatterns: [
            'C:\\Logs\\*'
          ]
          streams: [
            'Custom-Json-LogFileFormat'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'la-data-destination'
          workspaceResourceId: workspaceResourceId
        }
      ]
    }
    dataFlows: [
      {
        destinations: [
          'la-data-destination'
        ]
        streams: [
          'Microsoft-InsightsMetrics'
          'Microsoft-ServiceMap'
          'Microsoft-Event'
        ]
      }
      {
        destinations: [
          'la-data-destination'
        ]
        streams: [
          'Custom-Tomcat-Deamon-LogFileFormat'
        ]
        outputStream: 'Custom-TomcatLogs_CL'
        transformKql: 'source | project TimeGenerated, Message = RawData, FilePath'
      }
      {
        destinations: [
          'la-data-destination'
        ]
        streams: [
          'Custom-Json-LogFileFormat'
        ]
        outputStream: 'Custom-ApplicationJsonLogs_CL'
        transformKql: 'source | extend d=todynamic(RawData) | extend p=todynamic(d.Properties) | project TimeGenerated, Level=tostring(d.Level), Message=tostring(d.RenderedMessage), Properties=p'
      }
    ]
  }
}

output dcrId string = dcr.id
