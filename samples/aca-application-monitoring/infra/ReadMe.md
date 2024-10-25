## Deploying the infrastructure

This folder contains the bicep files to deploy the infrastructure for the Azure Container Apps application monitoring solution.

First create a bicep parameter file 'main.bicepparams' with the following content: 
```bicep
using 'main.bicep'

param appName = '<your-app-name>'
// One of the supported regions for Azure API Management Standard V2 SKU
param location = 'germanywestcentral'

param publisherEmail = 'your.name@example.com'
param publisherName = 'Your name'

param sqlAdminPassword = '<A strong sql password>'
```

```bash
az deployment sub create -n <your-deployment-name> -l germanywestcentral --template-file main.bicep --parameters main.bicepparam
```

This will create a Data Collection Rule (DCR) workspace transform and a Log Analytics workspace. The DCR will need be connected to the workspace in the next step.

### Connect workspace transforms

To connect the workspace transform DCR to the workspace, you need to run the following command:

```bash
az rest --method patch --headers Content-Type=application/json --url https://management.azure.com/subscriptions/{subscription}/resourcegroups/{resourcegroup}/providers/microsoft.operationalinsights/workspaces/{workspace}?api-version=2021-12-01-preview --body "{'properties': { 'defaultDataCollectionRuleResourceId': '/subscriptions/{subscription}/resourceGroups/{resourcegroup}/providers/Microsoft.Insights/dataCollectionRules/{DCR}'} }"
```