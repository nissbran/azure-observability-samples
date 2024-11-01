﻿using Azure.Monitor.OpenTelemetry.Exporter;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Serilog;
using Serilog.Formatting.Compact;
using Serilog.Sinks.OpenTelemetry;
using Serilog.Sinks.SystemConsole.Themes;

namespace BookingProcessor.Telemetry;

internal static class ObservabilityConfiguration
{
    public static HostApplicationBuilder ConfigureTelemetry(this HostApplicationBuilder builder, string serviceNamespace, string application, string team)
    {
        var resourceBuilder = ResourceBuilder.CreateDefault();

        var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
        var otlpEndpoint = builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"];
        var useSerilogForOtel = builder.Configuration.GetValue("USE_SERILOG_FOR_OTEL", true);

        if (!string.IsNullOrEmpty(appInsightsConnectionString))
        {
            Log.Verbose("Application Insights connection string configured, using OpenTelemetry logging exporter for Application Insights");
            builder.Services.AddLogging(logging =>
            {
                logging.AddOpenTelemetry(builderOptions =>
                {
                    builderOptions.SetResourceBuilder(resourceBuilder);
                    builderOptions.IncludeFormattedMessage = true;
                    builderOptions.IncludeScopes = false;
                    builderOptions.AddAzureMonitorLogExporter(options => options.ConnectionString = appInsightsConnectionString);
                });
            });
        }
        else
        {
            if (useSerilogForOtel)
            {
                Log.Verbose("Using Serilog for logging");
                builder.Services.AddSerilog((context, configuration) => 
                {
                    var serilogConfiguration = configuration
                        .ReadFrom.Configuration(builder.Configuration)
                        .Enrich.FromLogContext();

                    if (builder.Environment.IsDevelopment() || builder.Configuration.GetValue<bool>("USE_CONSOLE_LOG_OUTPUT"))
                    {
                        if (builder.Configuration.GetValue<bool>("USE_CONSOLE_JSON_LOG_OUTPUT"))
                        {
                            Log.Verbose("Using console log output with JSON formatter");
                            serilogConfiguration.WriteTo.Console(formatter: new RenderedCompactJsonFormatter());
                        }
                        else
                        {
                            Log.Verbose("Using console log output with text formatter");
                            serilogConfiguration.WriteTo.Console(theme: AnsiConsoleTheme.Sixteen);
                        }
                    }

                    if (!string.IsNullOrEmpty(otlpEndpoint))
                    {
                        var protocol = builder.Configuration["OTEL_EXPORTER_OTLP_PROTOCOL"] == "http/protobuf"
                            ? OtlpProtocol.HttpProtobuf
                            : OtlpProtocol.Grpc;

                        Log.Verbose("Using OpenTelemetry Protocol (OTLP) endpoint {OtlpEndpoint} with {Proctocol}, for Serilog", otlpEndpoint, protocol);
                        serilogConfiguration.WriteTo.OpenTelemetry(options =>
                        {
                            options.HttpMessageHandler = new SocketsHttpHandler { ActivityHeadersPropagator = null };
                            options.Protocol = protocol;
                            options.Endpoint = protocol == OtlpProtocol.HttpProtobuf ? $"{otlpEndpoint}/v1/logs" : otlpEndpoint;
                            options.Headers = GetSerilogSpecificOtelHeaders(builder);
                            options.ResourceAttributes = resourceBuilder.Build().Attributes.ToDictionary();
                        });
                    }
                    else
                    {
                        Log.Verbose("OpenTelemetry Protocol (OTLP) endpoint not configured, using default Serilog configuration");
                        serilogConfiguration
                            .Enrich.WithProperty("namespace", serviceNamespace)
                            .Enrich.WithProperty("application", application)
                            .Enrich.WithProperty("team", team);
                    }

                    var seqEndpoint = builder.Configuration["SEQ_ENDPOINT"];
                    if (!string.IsNullOrEmpty(seqEndpoint))
                    {
                        Log.Verbose("Seq endpoint configured, using Seq for logging");
                        serilogConfiguration.WriteTo.Seq(seqEndpoint);
                    }
                });
            }
            else
            {
                builder.Services.AddLogging(logging =>
                {
                    if (!string.IsNullOrEmpty(otlpEndpoint))
                    {
                        Log.Verbose("Using OpenTelemetry Protocol (OTLP) endpoint {OtlpEndpoint} for OpenTelemetry logging", otlpEndpoint);

                        logging.AddOpenTelemetry(builderOptions =>
                        {
                            builderOptions.SetResourceBuilder(resourceBuilder);
                            builderOptions.IncludeFormattedMessage = true;
                            builderOptions.IncludeScopes = false;
                            builderOptions.AddOtlpExporter();
                        });
                    }
                });
            }
        }

        builder.Services.AddOpenTelemetry()
            .WithTracing(tracingBuilder =>
            {
                if (!string.IsNullOrEmpty(appInsightsConnectionString))
                {
                    Log.Verbose("Application Insights connection string configured, using OpenTelemetry tracing exporter for Application Insights");
                    tracingBuilder.AddAzureMonitorTraceExporter(options =>
                    {
                        options.ConnectionString = appInsightsConnectionString;
                        // This is sampled by hashing the traceid with hash seed 5381
                        // This is the same in the java sampler as well
                        //options.SamplingRatio = 0.1f;
                    });
                }
                else if (!string.IsNullOrEmpty(otlpEndpoint))
                {
                    Log.Verbose("Using OpenTelemetry Protocol (OTLP) endpoint {OtlpEndpoint} for OpenTelemetry tracing", otlpEndpoint);
                    tracingBuilder.AddOtlpExporter();
                }

                tracingBuilder
                    .SetResourceBuilder(resourceBuilder)
                    .AddHttpClientInstrumentation();
            })
            .WithMetrics(metricsBuilder =>
            {
                if (!string.IsNullOrEmpty(appInsightsConnectionString))
                {
                    Log.Verbose("Application Insights connection string configured, using OpenTelemetry metrics exporter for Application Insights");
                    metricsBuilder.AddAzureMonitorMetricExporter(options =>
                    {
                        options.ConnectionString = appInsightsConnectionString;
                    });
                }
                else if (!string.IsNullOrEmpty(otlpEndpoint))
                {
                    Log.Verbose("Using OpenTelemetry Protocol (OTLP) endpoint {OtlpEndpoint} for OpenTelemetry metrics", otlpEndpoint);
                    metricsBuilder.AddOtlpExporter();
                }

                metricsBuilder
                    .AddConsumedEventsMetrics()
                    .SetResourceBuilder(resourceBuilder)
                    .AddHttpClientInstrumentation()
                    .AddRuntimeInstrumentation();
            });

        return builder;
    }

    private static Dictionary<string, string> GetSerilogSpecificOtelHeaders(HostApplicationBuilder builder)
    {
        var headerDictionary = new Dictionary<string, string>();
        try
        {
            var headers = builder.Configuration["OTEL_EXPORTER_OTLP_HEADERS"];
            var apiKey = headers?.Split(";").FirstOrDefault(h => h.StartsWith("x-otlp-api-key"))?.Split("=")[1];
            if (!string.IsNullOrEmpty(apiKey))
            {
                headerDictionary.Add("x-otlp-api-key", apiKey);
            }
        }
        catch (Exception e)
        {
            Log.Verbose(e, "Error while reading OTEL_EXPORTER_OTLP_HEADERS: {Error}", e.Message);
        }
        return headerDictionary;
    }
}