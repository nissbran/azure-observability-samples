# ACA Application Monitoring

This sample demonstrates how to monitor an application running on Azure Container Apps with Azure Monitor and App Insights using Open Telemetry. The sample application is a simple credit booking application that consists of two services: a credit API and a booking processor. The credit API provides a REST API to create a credit and add transactions to it. The booking processor consumes the booking messages and processes bookings.

Disclaimer: This is not an official Microsoft repository. The samples are provided as-is without any warranty. Use at your own risk.

Disclaimer 2: This repostory uses 2 preview features:
* Azure Container Apps Open Telemetry Agents
* Trace support for Azure Service Bus

## Run the application locally with .NET Aspire

This demo is run locally with .NET Aspire. To run, start with the aspire AppHost project. To avoid issues with the building of the credit api, first you need to restore the dotnet tool manifest in the [.NET Solution Folder](src/dotnet/) folder:

```powershell
dotnet tool restore
```

## Publish to Azure

This demo is publish to Azure Container Apps.

[Deploy to Azure Container Apps](infrastructure/azure-container-apps/ReadMe.md)

## Build and publish the containers to Azure Container Registry using the Azure CLI

To build and publish the containers to Azure Container Registry using the Azure CLI, you need to have the Azure CLI installed and logged in. The docker context will be zippped and uploaded to Azure Container Registry and the image will be built in the cloud.

```powershell
$ENV:ACR="your_acr_name"
az acr build --registry $ENV:ACR --image credits/credit-api:1.0 src/dotnet/credit-api/.
az acr build --registry $ENV:ACR --image credits/booking-processor:1.0 src/dotnet/
az acr build --registry $ENV:ACR --image credits/booking-api:1.0 src/dotnet/booking-api/.
```

## Build and publish the containers to Azure Container Registry using the .NET CLI and Docker

To build and publish the containers to Azure Container Registry using the .NET CLI and Docker, you need to have Docker installed and running. You also need to have the Azure CLI installed and logged in.

```powershell
$ENV:ACR="your_acr_name"
$ENV:ACRFQDN=$ENV:ACR + ".azurecr.io"
az acr login --name $ENV:ACR
dotnet publish src/dotnet/credit-api/ -c Release --os linux --arch x64 /t:PublishContainer -p ContainerRegistry=$ENV:ACRFQDN -p ContainerImageTag=1.0
dotnet publish src/dotnet/booking-processor/ -c Release --os linux --arch x64 /t:PublishContainer -p ContainerRegistry=$ENV:ACRFQDN -p ContainerImageTag=1.0
dotnet publish src/dotnet/booking-api/ -c Release --os linux --arch x64 /t:PublishContainer -p ContainerRegistry=$ENV:ACRFQDN -p ContainerImageTag=1.0
```

## To run the Rest test client

To run the Rest test client with the file `http-test.http`, you need to add a .env file with the following content:
```
apimSubscriptionKey=yourApimSubscriptionKey
apimGatewayApiUrl=https://yourApimGatewayUrl/yourApi
```
