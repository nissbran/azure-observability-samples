using CreditApi.Data;
using CreditApi.Messaging;
using CreditApi.Modules.Credit;
using CreditApi.Telemetry;
using Serilog;

namespace CreditApi;

internal static class ApplicationConfiguration
{
    public static WebApplication ConfigureServices(this WebApplicationBuilder builder)
    {
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen();
        builder.Services.AddHealthChecks(); 
        builder.Services.AddServiceDiscovery();
        builder.Services.ConfigureHttpClientDefaults(http =>
        {
            // Turn on resilience by default
            http.AddStandardResilienceHandler();

            // Turn on service discovery by default
            http.AddServiceDiscovery();
        });
        
        builder.AddSqlServerDbContext<CreditDbContext>("credit-db");
        builder.AddAzureServiceBusClient("messaging");
        builder.Services.AddSingleton<IBookingEventSender, ServiceBusBookingEventSender>();

        builder.Services.AddCreditModule();
        
        
        return builder.Build();
    }

    public static WebApplication ConfigurePipeline(this WebApplication app)
    {
        if (app.Environment.IsDevelopment())
        {
            app.UseSwagger();
            app.UseSwaggerUI();
        }

        app.UseHealthChecks("/healthz");
        if (ObservabilityConfiguration.IsSerilogConfigured)
        {
            app.UseSerilogRequestLogging();
        }
        
        CreditModule.MapRoutes(app);
        
        return app;
    }
}