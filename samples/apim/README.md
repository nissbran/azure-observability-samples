# Azure API Management (APIM) Monitoring

This sample contains policies and scripts for monitoring and managing Azure API Management services. It demonstrates how to configure APIM policies and use observability features to monitor API traffic and performance.

**Disclaimer**: This is not an official Microsoft repository. The samples are provided as-is without any warranty. Use at your own risk.

## Prerequisites

Before using these samples, ensure you have:

* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - for managing Azure resources
* An Azure subscription with an active API Management instance
* A REST client that supports `.http` files (e.g., [REST Client extension for VS Code](https://marketplace.visualstudio.com/items?itemName=humao.rest-client))

## Contents

### Policies

The `policies/` directory contains APIM policy templates:

* **base.cshtml** - Base policy template with standard inbound, backend, outbound, and error handling sections
* **apis/** - API-specific policy configurations
* **fragments/** - Reusable policy fragments, including validation policies

### Scripts

The `scripts/` directory contains HTTP test files for interacting with APIM:

* **tracing.http** - Scripts for testing API tracing and diagnostics
* **workspaces.http** - Scripts for managing APIM workspaces

## Configuration

To use the HTTP test scripts, create a `.env` file in the scripts directory with the following variables:

```
clientId=<your-client-id>
clientSecret=<your-client-secret>
tenantId=<your-tenant-id>
subscriptionId=<your-subscription-id>
resourceGroupName=<your-resource-group>
apimServiceName=<your-apim-service-name>
apimSubscriptionKey=<your-apim-subscription-key>
apimGatewayUrl=<your-apim-gateway-url>
```

## Usage

1. Configure your Azure API Management instance
2. Apply the desired policies from the `policies/` directory to your APIM instance
3. Create the `.env` file with your configuration values
4. Use the HTTP files in the `scripts/` directory to test and monitor your APIs

## Resources

* [Azure API Management Documentation](https://docs.microsoft.com/en-us/azure/api-management/)
* [APIM Policies Reference](https://docs.microsoft.com/en-us/azure/api-management/api-management-policies)
* [APIM Observability](https://docs.microsoft.com/en-us/azure/api-management/observability)
