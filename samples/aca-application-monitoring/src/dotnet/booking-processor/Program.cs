using BookingProcessor;
using BookingProcessor.Telemetry;
using Serilog;
using Serilog.Events;
using Serilog.Sinks.SystemConsole.Themes;

const string appName = "booking-processor";

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Verbose()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}", theme: AnsiConsoleTheme.Sixteen)
    .CreateBootstrapLogger();

Log.Information("Starting up {Application}", appName);

try
{
    // This is to enable tracing for the Service Bus Azure SDK, currently in preview
    AppContext.SetSwitch("Azure.Experimental.EnableActivitySource", true);
    
    var builder = Host.CreateApplicationBuilder(args);

    builder.Configuration.AddJsonFile("appsettings.json", false);
    builder.Configuration.AddJsonFile("appsettings.local.json", true);

    var host = builder
        .ConfigureTelemetry("credits", appName, "team 1")
        .ConfigureServices();
    host.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Unhandled exception when starting {Application}", appName);
}
finally
{
    Log.Information("Shut down complete for {Application}", appName);
    Log.CloseAndFlush();
}
