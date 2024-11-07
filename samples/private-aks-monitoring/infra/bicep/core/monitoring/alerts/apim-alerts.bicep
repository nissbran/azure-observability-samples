param apimResourceId string
param actionGroupResourceId string

resource apimCapacityAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-appim-Capacity'
  location: 'Global'
  properties: {
    actions: [
      {
        actionGroupId: actionGroupResourceId
      }
    ]
    description: 'Utilization metric for ApiManagement service'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'CapacityOverThreshold'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'Capacity'
          metricNamespace: 'Microsoft.ApiManagement/service'
          operator: 'GreaterThan' 
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      apimResourceId
    ]
    severity: 3
    windowSize: 'PT5M'
  }
}
