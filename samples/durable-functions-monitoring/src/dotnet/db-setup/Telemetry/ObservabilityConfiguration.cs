using Microsoft.Extensions.Hosting;
using OpenTelemetry.Resources;
using Serilog;
using Serilog.Sinks.OpenTelemetry;
using Serilog.Sinks.SystemConsole.Themes;

namespace DbSetup.Telemetry;

internal static class ObservabilityConfiguration
{
    public static HostApplicationBuilder ConfigureTelemetry(this HostApplicationBuilder builder)
    {
        var resourceBuilder = ResourceBuilder.CreateDefault();

        var otlpEndpoint = builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"];

        builder.Services.AddSerilog((context, configuration) =>
        {
            var serilogConfiguration = configuration
                .ReadFrom.Configuration(builder.Configuration)
                .Enrich.FromLogContext()
                .WriteTo.Console(theme: AnsiConsoleTheme.Sixteen);

            if (!string.IsNullOrEmpty(otlpEndpoint))
            {
                var protocol = builder.Configuration["OTEL_EXPORTER_OTLP_PROTOCOL"] == "http/protobuf"
                    ? OtlpProtocol.HttpProtobuf
                    : OtlpProtocol.Grpc;

                serilogConfiguration.WriteTo.OpenTelemetry(options =>
                {
                    options.HttpMessageHandler = new SocketsHttpHandler { ActivityHeadersPropagator = null };
                    options.Protocol = protocol;
                    options.Endpoint = protocol == OtlpProtocol.HttpProtobuf ? $"{otlpEndpoint}/v1/logs" : otlpEndpoint;
                    options.Headers = GetSerilogSpecificOtelHeaders(builder);
                    options.ResourceAttributes = resourceBuilder.Build().Attributes.ToDictionary();
                });
            }
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