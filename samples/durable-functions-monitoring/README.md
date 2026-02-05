# Durable Functions Monitoring

This sample demonstrates how to monitor long-running orchestrations with Azure Durable Functions. It includes an example implementation of a task tracking application that orchestrates and monitors long-running tasks, providing insights into their status and completion.

**Disclaimer**: This is not an official Microsoft repository. The samples are provided as-is without any warranty. Use at your own risk.

## Prerequisites

Before working with this sample, ensure you have:

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - for deploying and managing Azure resources
* [.NET SDK](https://dotnet.microsoft.com/download) (version 8.0 or later) - for building and running the application
* [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) - for local development and testing
* An active Azure subscription

## Features

This sample includes:

* **Task Tracking Application** - A Durable Functions application demonstrating long-running task orchestration
* **Multiple Storage Providers** - Support for both SQL-backed storage and Azure Managed Durable Task Scheduler
* **Monitoring and Observability** - Integration with Application Insights for tracking orchestration execution
* **Infrastructure as Code** - Bicep templates for deploying the required Azure resources

## Project Structure

* `src/dotnet/task-tracking/` - Main Durable Functions application for task tracking
* `src/dotnet/aspire/` - .NET Aspire host for local development
* `src/dotnet/mock-api/` - Mock external system API for testing
* `src/dotnet/db-setup/` - Database setup utilities
* `infra/` - Bicep templates for infrastructure deployment

## Storage Configuration

The application supports two storage provider configurations:

### SQL-Backed Storage

Configure SQL-backed storage in the `host.json` file:

```json
"storageProvider": {
    "type": "mssql",
    "connectionStringName": "ConnectionStrings:task-tracking-hub",
    "taskEventLockTimeout": "00:02:00",
    "createDatabaseIfNotExists": true
}
```

### Azure Managed Durable Task Scheduler

Configure Azure Managed Durable Task Scheduler in the `host.json` file:

```json
"storageProvider": {
    "type": "AzureManaged",
    "connectionStringName": "DURABLE_TASK_SCHEDULER_CONNECTION_STRING"
}
```

More information on the Azure Managed Durable Task Scheduler provider can be found in the [official documentation](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-task-scheduler/quickstart-durable-task-scheduler?pivots=csharp).

## Deployment

To deploy the infrastructure to Azure, follow the instructions in the [infra/ReadMe.md](infra/ReadMe.md) file.

## Local Development

For local development and testing, you can use the .NET Aspire host:

1. Navigate to the Aspire host directory:
   ```bash
   cd src/dotnet/aspire
   ```

2. Run the application:
   ```bash
   dotnet run
   ```

## Monitoring

The application integrates with Application Insights to provide:

* Orchestration execution tracking
* Performance metrics
* Custom telemetry and logging
* Dependency tracking for external calls

## Resources

* [Azure Durable Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/durable/)
* [Durable Functions Monitoring](https://docs.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-diagnostics)
* [Application Insights for Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-monitoring)
