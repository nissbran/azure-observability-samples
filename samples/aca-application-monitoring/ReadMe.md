## Run the application locally with .NET Aspire

This demo is run locally with .NET Aspire. To run, start with the aspire AppHost project. To avoid issues with the building of the credit api, first you need to restore the dotnet tool manifest in the [.NET Solution Folder](src/dotnet/) folder:

```powershell
dotnet tool restore
```

## Publish to Azure

This demo is publish to Azure Container Apps.

[Deploy to Azure Container Apps](infrastructure/azure-container-apps/ReadMe.md)

## Build and publish the containers to Azure Container Registry

```powershell
$ENV:ACR="your_acr_name"
az acr build --registry $ENV:ACR --image credits/credit-api:1.0 src/dotnet/credit-api/.
az acr build --registry $ENV:ACR --image credits/booking-processor:1.0 src/dotnet/booking-processor/.
```

## To run the Rest test client

To run the Rest test client with the file `http-test.http`, you need to add a .env file with the following content:
```
apimSubscriptionKey=yourApimSubscriptionKey
apimGatewayApiUrl=https://yourApimGatewayUrl/yourApi
```
