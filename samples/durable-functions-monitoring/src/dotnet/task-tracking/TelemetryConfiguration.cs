using System;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.Extensions.DependencyInjection;
using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

namespace TaskTracking;

public static class TelemetryConfiguration
{
    public static FunctionsApplicationBuilder ConfigureTelemetry(this FunctionsApplicationBuilder builder)
    {
        AppContext.SetSwitch("Azure.Experimental.EnableActivitySource", true);
        
        builder.Services.AddOpenTelemetry()
            .UseFunctionsWorkerDefaults()
            .WithTracing(tracingBuilder =>
            {
                tracingBuilder
                    .AddSource("DurableTask.Core")
                    .AddHttpClientInstrumentation()
                    .AddEntityFrameworkCoreInstrumentation();
                if (!string.IsNullOrEmpty(builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]))
                {
                    tracingBuilder.AddOtlpExporter();
                }
                
                if (!string.IsNullOrEmpty(builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
                {
                    tracingBuilder.AddAzureMonitorTraceExporter();
                }
            })
            .WithMetrics(metricsBuilder =>
            {
                metricsBuilder
                    .AddMeter("DurableTask.Core")
                    .AddHttpClientInstrumentation();
                if (!string.IsNullOrEmpty(builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]))
                {
                    metricsBuilder.AddOtlpExporter();
                }
                
                if (!string.IsNullOrEmpty(builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"]))
                {
                    metricsBuilder.AddAzureMonitorMetricExporter();
                }
            });
        
        return builder;
    }
}