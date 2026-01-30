using System;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using TaskTracking;

Console.OutputEncoding = System.Text.Encoding.UTF8;

var builder = FunctionsApplication.CreateBuilder(args);

builder.Services.ConfigureHttpClientDefaults(static http =>
{
    // Turn on service discovery by default
    //http.AddServiceDiscovery();
    http.AddStandardResilienceHandler();
});
builder.Services.AddHttpClient("ExternalSystem", client =>
{
    client.BaseAddress = new Uri("https://localhost:7277");
});
builder.Services.AddHttpClient("ExternalSystem2", client =>
{
    client.BaseAddress = new Uri("https://external-system-api");
});

builder.AddAzureBlobContainerClient("file-storage");
builder.ConfigureFunctionsWebApplication();
builder.ConfigureTelemetry();

using IHost app = builder.Build();

app.Run();