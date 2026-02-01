using System.Diagnostics;

namespace ExternalSystemMockApi;

public sealed class ProcessRequestScheduler(IProcessRequestService service, ILogger<ProcessRequestScheduler> logger) : BackgroundService
{
    private static readonly TimeSpan PollInterval = TimeSpan.FromSeconds(1);
    private static readonly TimeSpan CallbackDelay = TimeSpan.FromSeconds(10);
    
    private static readonly ActivitySource ActivitySource = new ActivitySource("ExternalSystemMockApi.ProcessRequestScheduler");

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(PollInterval);

        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            var dueRequests = service.DequeueScheduledDueRequests(CallbackDelay, DateTimeOffset.UtcNow);

            foreach (var request in dueRequests)
            {
                try
                {
                    using var activity =  ActivitySource.StartActivity("SendProcessRequestCallback", ActivityKind.Internal,
                        parentContext: request.TraceId.HasValue ? new ActivityContext(request.TraceId.Value, ActivitySpanId.CreateRandom(), ActivityTraceFlags.Recorded) : default);
                   
                    await service.SendAsync(request, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    logger.LogInformation("Callback send canceled for instance {InstanceId}.", request.InstanceId);
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "Failed to send callback for instance {InstanceId}.", request.InstanceId);
                }
            }
        }
    }
}