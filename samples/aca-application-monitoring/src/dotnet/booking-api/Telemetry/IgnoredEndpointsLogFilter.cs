using Serilog.Core;
using Serilog.Events;

namespace BookingApi.Telemetry;

public class IgnoredEndpointsLogFilter : ILogEventFilter
{
    public bool IsEnabled(LogEvent logEvent)
    {
        if (logEvent.Properties.TryGetValue("RequestPath", out var requestPath))
        {
            if (requestPath.ToString().Contains("/metrics") || 
                requestPath.ToString().Contains("/healthz") ||
                requestPath.ToString().Contains("/scalar") ||
                requestPath.ToString().Contains("/openapi"))
                return false;
        }

        return true;
    }
}