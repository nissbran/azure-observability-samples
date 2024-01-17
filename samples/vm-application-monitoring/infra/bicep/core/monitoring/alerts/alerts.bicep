param appgatewayId string
param applogsWorkspaceId string
param location string

@description('Email addresses to which the notifications should be sent. Should be specified as an array of strings, for example, ["user1@contoso.com", "user2@contoso.com"].')
param emailAddress array
@description('Short name of the action group used for display purposes. Can be 1-12 characters in length.')
@maxLength(12)
param actionGroupShortName string = 'ag-${((length(resourceGroup().name) >= 9) ? substring(resourceGroup().name, 0, 9) : resourceGroup().name)}'

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${resourceGroup().name}'
  location: 'Global'
  properties: {
    emailReceivers: [for item in emailAddress: {
      name: 'emailReceivers-${uniqueString(item)}'
      emailAddress: item
      useCommonAlertSchema: true
    }]
    groupShortName: actionGroupShortName
    enabled: true
  }
}

module appgwAlerts 'appgw-alerts.bicep' = {
  name: 'appgwAlerts'
  params: {
    appgatewayId: appgatewayId
    actionGroupId: actionGroup.id
  }
}

module appAlerts 'application-alerts.bicep' = {
  name: 'appAlerts'
  params: {
    actionGroupId: actionGroup.id
    workspaceId: applogsWorkspaceId
    location: location
  }
}
