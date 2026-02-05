# Azure Monitor for Application VMs

This setup is for monitoring application VMs with Azure Monitor and Data Collection Rules. The setup consists of the following components:
* 2 Data Collection Rules
  * One for collecting VM application logs and metrics 
  * One for collecting security events
* 1 Data Collection Endpoint
  * As a configuration endpoint for the VMs
  * As an ingestion endpoint for the logs and metrics
* 2 Log Analytics workspaces
  * One for storing VM application logs and metrics
  * One for storing security events
* Azure Managed Grafana
* 2 Windows application VMs
  * Needs some manual install of Tomcat and Windows firewall rules
  * Extension for installing the Azure Monitor Agent
  * Extension for installing the Dependency Agent (VM Insights)
* 1 Application Gateway
* Network setup with Azure Monitor Private Link Scope

![architecture](docs/architecture.png)

## Prerequisites

Before deploying this sample, ensure you have:

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - for deploying and managing Azure resources
* An active Azure subscription with appropriate permissions
* Basic knowledge of Azure Virtual Machines and Azure Monitor
* Access to configure Windows VMs (for Tomcat installation and firewall configuration)

## Deploy the setup

To deploy with bicep go to the [infra/bicep](infra/bicep) folder and follow the instructions in the [ReadMe.md](infra/bicep/README.md).

## Use Azure Data Explorer with Log Analytics

To use Azure Data Explorer with Log Analytics you need connect to the Log Analytics workspace with the following URL given that your logged in to the Azure Data Explorer portal with a user with access to the Log Analytics workspace. The portal is https://dataexplorer.azure.com.

`https://ade.loganalytics.io/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>`