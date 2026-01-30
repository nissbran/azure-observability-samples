## Deploying the infrastructure

This folder contains the bicep files to deploy the infrastructure for the Durable Functions monitoring solution.

First create a bicep parameter file 'main.bicepparams' with the following content: 
```bicep
using 'main.bicep'

param appName = '<your-app-name>'
param location = 'swedencentral'

param publisherEmail = 'your.name@example.com'
param publisherName = 'Your name'

param sqlAdminPassword = '<A strong sql password>'
```

