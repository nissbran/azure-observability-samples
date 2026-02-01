# Task Tracking

This project contains an example implementation of a Durable Functions application that tracks the progress of long-running tasks. It demonstrates how to use Durable Functions to orchestrate and monitor tasks, providing insights into their status and completion.

## Storage Configuration

Storage configruration for SQL backed Durable Functions is done in the `host.json` file. Below is an example configuration snippet:
```Json
"storageProvider": {
    "type": "mssql",
    "connectionStringName": "ConnectionStrings:task-tracking-hub",
    "taskEventLockTimeout": "00:02:00",
    "createDatabaseIfNotExists": true
},
```

It is also possible to use the Azure Managed Durable Task Scheduler provider for Durable Functions by configuring the `host.json` file as shown below:
More information on the Azure Managed Durable Task Scheduler provider can be found [here](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-task-scheduler/quickstart-durable-task-scheduler?pivots=csharp).
```Json
"storageProvider": {
    "type": "AzureManaged",
    "connectionStringName": "DURABLE_TASK_SCHEDULER_CONNECTION_STRING"
}
```
## Start Emulator

To start the 