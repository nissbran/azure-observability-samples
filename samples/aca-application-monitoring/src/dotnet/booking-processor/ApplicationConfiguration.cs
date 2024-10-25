using BookingProcessor.Data;
using BookingProcessor.Services;
using BookingProcessor.Subscriptions;
using BookingProcessor.Telemetry;
using Microsoft.EntityFrameworkCore;

namespace BookingProcessor;

internal static class ApplicationConfiguration
{
    public static IHost ConfigureServices(this HostApplicationBuilder builder)
    {
        builder.Services.ConfigureHttpClientDefaults(http =>
        {
            // Turn on resilience by default
            http.AddStandardResilienceHandler();

            // Turn on service discovery by default
            http.AddServiceDiscovery();
        });
        builder.AddAzureServiceBusClient("messaging");
        
        var connectionString = builder.Configuration.GetConnectionString("booking-db");
        builder.Services.AddPooledDbContextFactory<BookingDbContext>(dbContextOptionsBuilder => dbContextOptionsBuilder.UseSqlServer(connectionString));
        builder.EnrichSqlServerDbContext<BookingDbContext>();
        
        builder.Services.AddSingleton<EventConsumedMetrics>();
        
        builder.Services.AddSingleton<BookingEventHandler>();
        builder.Services.AddHostedService<BookingSubscriptionService>();

        return builder.Build();
    }
}