# Azure Observability Samples

This repository contains sample implementations demonstrating various observability setups in Azure using Azure Monitor, Application Insights, and other Azure monitoring services.

**Disclaimer**: This is not an official Microsoft repository. The samples are provided as-is without any warranty. Use at your own risk.

## Prerequisites

Before working with these samples, ensure you have the following tools installed:

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - for deploying and managing Azure resources
* [.NET SDK](https://dotnet.microsoft.com/download) (version 8.0 or later) - for building and running .NET applications
* [Docker Desktop](https://www.docker.com/products/docker-desktop) - for building and running containerized applications
* [kubectl](https://kubernetes.io/docs/tasks/tools/) - for managing Kubernetes clusters (AKS samples)
* An active Azure subscription with appropriate permissions to create resources

## Samples

This repository includes the following observability samples:

### 1. [Azure Monitor for Application VMs](/samples/vm-application-monitoring/README.md)
Demonstrates monitoring application virtual machines using Azure Monitor with Data Collection Rules, including VM application logs, metrics, and security events.

### 2. [Azure Monitor for Azure Kubernetes Service (AKS)](/samples/private-aks-monitoring/README.md)
Shows how to set up monitoring for applications running on Azure Kubernetes Service with Azure Monitor and Data Collection Rules.

### 3. [Azure Container Apps Application Monitoring](/samples/aca-application-monitoring/ReadMe.md)
Illustrates monitoring applications on Azure Container Apps using Azure Monitor, Application Insights, and OpenTelemetry.

### 4. [Azure API Management (APIM) Monitoring](/samples/apim/README.md)
Contains policies and scripts for monitoring and managing Azure API Management services.

### 5. [Durable Functions Monitoring](/samples/durable-functions-monitoring/README.md)
Demonstrates monitoring long-running orchestrations with Azure Durable Functions, including SQL-backed and Azure Managed Durable Task Scheduler options.

## Getting Started

Each sample includes its own README with specific instructions for deployment and configuration. Navigate to the individual sample directories to get started.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve these samples.

## License

See the [LICENSE](LICENSE) file for details.
