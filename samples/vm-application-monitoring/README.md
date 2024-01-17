# Azure Monitor for application vms

This setup is for monitoring application vms with Azure Monitor and Data Collection Rules. The setup consists of the following components:
* 2 Data Collection Rules
  * One for collecting vm application logs and metrics 
  * One for collecting security events
* 1 Data Collection Endpoint
  * As an configuration endpoint for the vms
  * As an ingestion endpoint for the logs and metrics
* 2 Log Analytics workspaces
  * One for storing vm application logs and metrics
  * One for storing security events
* Azure Managed Grafana
* 2 windows application vms
  * Needs some manual install of tomcat and windows firewall rules
  * Extension for installing the Azure Monitor Agent
  * Extension for installing the Dependency Agent (VmInsights)
* 1 application gateway
* Network setup with Azure Monitor Private Link Scope

![architecture](docs/architecture.png)

## Deploy the setup

To deploy the setup you need to have the following tools installed:
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)