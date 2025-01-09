using System.Globalization;
using System.Threading.RateLimiting;
using CreditApi.Data;
using CreditApi.Messaging;
using CreditApi.Modules.Credit;
using CreditApi.Telemetry;
using Microsoft.AspNetCore.RateLimiting;
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

        // Aspire integration services -----------------------------------------
        builder.AddSqlServerDbContext<CreditDbContext>("credit-db");
        builder.AddAzureServiceBusClient("messaging");
        // ---------------------------------------------------------------------

        builder.Services.AddRateLimiter(options =>
        {
            options.OnRejected = (context, token) => 
            {
                if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
                {
                    context.HttpContext.Response.Headers.RetryAfter = ((int)retryAfter.TotalSeconds).ToString(NumberFormatInfo.InvariantInfo);
                }

                context.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
                context.HttpContext.Response.WriteAsync("Too many requests. Please try again later.", cancellationToken: token);

                return new ValueTask();
            };
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.AddFixedWindowLimiter("FixedWindow", rateLimitOptions =>
            {
                rateLimitOptions.QueueLimit = 2;
                rateLimitOptions.AutoReplenishment = true;
                rateLimitOptions.Window = TimeSpan.FromSeconds(30);
                rateLimitOptions.PermitLimit = 5;
                rateLimitOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
            });
        });
        builder.Services.AddSingleton<IBookingEventSender, ServiceBusBookingEventSender>();

        builder.Services.AddCreditModule();
        
        return builder.Build();
    }

    public static WebApplication ConfigurePipeline(this WebApplication app)
    {
        app.UseSwagger();
        if (app.Environment.IsDevelopment())
        {
            app.UseSwaggerUI();
        }

        app.UseHealthChecks("/healthz");
        if (ObservabilityConfiguration.IsSerilogConfigured)
        {
            app.UseSerilogRequestLogging();
        }

        app.UseRateLimiter();
        
        CreditModule.MapRoutes(app);
        
        return app;
    }
}