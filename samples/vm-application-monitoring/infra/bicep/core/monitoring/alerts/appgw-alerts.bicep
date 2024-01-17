param appgatewayId string
param actionGroupId string

resource unhealthyHostCountAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-appgw-application-UnhealthyHostCount'
  location: 'Global'
  properties: {
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'UnhealthyHostCountCriteria'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'UnhealthyHostCount'
          operator: 'GreaterThan' 
          threshold: 0
          timeAggregation: 'Average'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      appgatewayId
    ]
    severity: 2
    windowSize: 'PT1M'
  }
}
