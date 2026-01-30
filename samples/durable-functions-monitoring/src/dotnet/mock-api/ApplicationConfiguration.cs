using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Serilog;

namespace ExternalSystemMockApi;

internal static class ApplicationConfiguration
{
    private const string HealthEndpointPath = "/health";
    private const string AlivenessEndpointPath = "/alive";
    
    public static WebApplication ConfigureServices(this WebApplicationBuilder builder)
    {
        builder.ConfigureOpenTelemetry();
        builder.AddDefaultHealthChecks();
        builder.Services.AddServiceDiscovery();
        builder.Services.AddSingleton<IProcessRequestService, ProcessRequestService>();
        builder.Services.AddHostedService<ProcessRequestScheduler>();
        builder.Services.AddHttpClient("callback-client", client =>
        {
            //client.BaseAddress = new Uri("https+http://task-tracking");
            client.BaseAddress = new Uri("http://localhost:7075");
        });

        return builder.Build();
    }

    public static WebApplication ConfigurePipeline(this WebApplication app)
    {
        app.MapDefaultEndpoints();
        app.UseSerilogRequestLogging();
        
        app.Map("/", () => "Hello, World!");
        app.MapPost("/process", async (ProcessRequest data, IProcessRequestService service, CancellationToken cancellationToken) =>
        {
            var processRequest = await service.ScheduleCallbackAsync(data, cancellationToken);

            return Results.Accepted($"/process/{processRequest.InstanceId}", new
            {
                Message = "Return callback scheduled.",
                InstanceId = processRequest.InstanceId
            });
        });

        app.MapPost("/process/trigger", async (IProcessRequestService service, CancellationToken cancellationToken) =>
        {
            var pending = service.DequeueAllScheduled();
            var results = new List<MockProcessResult>();

            foreach (var request in pending)
            {
                var result = await service.SendAsync(request, cancellationToken);
                results.Add(result);
            }

            return Results.Ok(new
            {
                Message = "Manual callback trigger executed.",
                Sent = results.Count,
                Results = results
            });
        });

        app.MapPost("/process/{instanceId}/trigger", async (string instanceId, IProcessRequestService service, CancellationToken cancellationToken) =>
        {
            if (!service.TryRemoveScheduled(instanceId, out var request))
            {
                return Results.NotFound(new
                {
                    Message = "No pending request found.",
                    InstanceId = instanceId
                });
            }

            var result = await service.SendAsync(request, cancellationToken);

            return Results.Ok(new
            {
                Message = "Manual callback trigger executed.",
                Result = result
            });
        });
        
        return app;
    }

    private static TBuilder ConfigureOpenTelemetry<TBuilder>(this TBuilder builder) where TBuilder : IHostApplicationBuilder
    {
        builder.Services.AddSerilog(configuration =>
        {
            configuration.Enrich.FromLogContext();
            configuration.WriteTo.Console();
            configuration.WriteTo.OpenTelemetry();
        });

        builder.Services.AddOpenTelemetry()
            .WithMetrics(metrics =>
            {
                metrics.AddAspNetCoreInstrumentation()
                    .AddHttpClientInstrumentation()
                    .AddOtlpExporter();
            })
            .WithTracing(tracing =>
            {
                tracing.AddSource(builder.Environment.ApplicationName)
                    .AddSource("ExternalSystemMockApi.ProcessRequestScheduler")
                    .AddAspNetCoreInstrumentation(tracing =>
                        // Exclude health check requests from tracing
                        tracing.Filter = context =>
                            !context.Request.Path.StartsWithSegments(HealthEndpointPath)
                            && !context.Request.Path.StartsWithSegments(AlivenessEndpointPath)
                    )
                    .AddHttpClientInstrumentation()
                    .AddOtlpExporter();
            });

        return builder;
    }
    
    
    public static TBuilder AddDefaultHealthChecks<TBuilder>(this TBuilder builder) where TBuilder : IHostApplicationBuilder
    {
        builder.Services.AddHealthChecks()
            // Add a default liveness check to ensure app is responsive
            .AddCheck("self", () => HealthCheckResult.Healthy(), ["live"]);

        return builder;
    }

    public static WebApplication MapDefaultEndpoints(this WebApplication app)
    {
        // Adding health checks endpoints to applications in non-development environments has security implications.
        // See https://aka.ms/dotnet/aspire/healthchecks for details before enabling these endpoints in non-development environments.
        if (app.Environment.IsDevelopment())
        {
            // All health checks must pass for app to be considered ready to accept traffic after starting
            app.MapHealthChecks(HealthEndpointPath);

            // Only health checks tagged with the "live" tag must pass for app to be considered alive
            app.MapHealthChecks(AlivenessEndpointPath, new HealthCheckOptions
            {
                Predicate = r => r.Tags.Contains("live")
            });
        }

        return app;
    }
    
}