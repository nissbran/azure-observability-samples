param nameSuffix string
param location string = resourceGroup().location
param workspaceResourceId string
param dataCollectionEndpointResourceId string

resource dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'dcr-security-win-vm-${nameSuffix}'
  location: location
  properties: {
    dataCollectionEndpointId: dataCollectionEndpointResourceId
    description: 'DCR for Security for windows Vms'
    dataSources: {
      windowsEventLogs: [
        {
          name: 'WindowsEventLogsDataSource'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            // Collect Security Log events with Event ID = 4648 and a process name of consent.exe
            'Security!*[System[(EventID=4648)]] and *[EventData[Data[@Name=\'ProcessName\']=\'C:\\Windows\\System32\\consent.exe\']]'
            // Collect all success and failure Security events except for Event ID 4624 (Successful logon)
            'Security!*[System[(band(Keywords,13510798882111488)) and (EventID != 4624)]]'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'la-security-destination'
          workspaceResourceId: workspaceResourceId
        }
      ]
    }
    dataFlows: [
      {
        destinations: [
          'la-security-destination'
        ]
        streams: [
          'Microsoft-Event'
        ]
      }
    ]
  }
}

output dcrId string = dcr.id
