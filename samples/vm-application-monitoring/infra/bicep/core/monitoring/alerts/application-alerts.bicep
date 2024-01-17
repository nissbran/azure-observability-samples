param workspaceId string
param actionGroupId string
param location string

resource errorsOver0 'Microsoft.Insights/scheduledQueryRules@2022-06-15' = {
  name: 'alert-application-log-ErrorsOver0'
  location: location
  properties: {
    actions: {
      actionGroups:[
        actionGroupId
      ]
    }
    criteria: {
      allOf: [
        {
        query: 'ApplicationJsonLogs_CL | where Level == \'Error\' | summarize Errors=count()'
        metricMeasureColumn: 'Errors'
        operator: 'GreaterThan'
        threshold: 0
        timeAggregation: 'Total'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      workspaceId
    ]
    severity: 2
    windowSize: 'PT30M'
  }
}
