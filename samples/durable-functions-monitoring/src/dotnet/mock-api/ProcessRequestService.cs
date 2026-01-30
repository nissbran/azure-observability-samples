using System.Collections.Concurrent;
using System.Diagnostics;

namespace ExternalSystemMockApi;

public interface IProcessRequestService
{
    Task<ProcessRequest> ScheduleCallbackAsync(ProcessRequest request, CancellationToken cancellationToken = default);
    Task<MockProcessResult> SendAsync(ProcessRequest request, CancellationToken cancellationToken = default);
    IReadOnlyList<ProcessRequest> DequeueScheduledDueRequests(TimeSpan delay, DateTimeOffset now);
    IReadOnlyList<ProcessRequest> DequeueAllScheduled();
    bool TryRemoveScheduled(string instanceId, out ProcessRequest request);
    bool TryGet(string instanceId, out ProcessRequest request);
}

public record MockProcessResult(
    string InstanceId,
    string Status,
    string Payload,
    DateTimeOffset CompletedUtc);

public sealed class ProcessRequestService : IProcessRequestService
{
    private readonly ConcurrentDictionary<string, ScheduledProcessRequest> _requests = new(StringComparer.OrdinalIgnoreCase);
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ProcessRequestService> _logger;

    public ProcessRequestService(IHttpClientFactory httpClientFactory, ILogger<ProcessRequestService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public Task<ProcessRequest> ScheduleCallbackAsync(ProcessRequest request, CancellationToken cancellationToken = default)
    {
        if (request == null)
        {
            throw new ArgumentNullException(nameof(request));
        }

        var instanceId = string.IsNullOrWhiteSpace(request.InstanceId)
            ? Guid.NewGuid().ToString("N")
            : request.InstanceId;

        var cachedRequest = new ProcessRequest
        {
            InstanceId = instanceId,
            DocumentType = request.DocumentType,
            TraceId = Activity.Current?.TraceId
        };

        _requests[instanceId] = new ScheduledProcessRequest(cachedRequest, DateTimeOffset.UtcNow);

        return Task.FromResult(cachedRequest);
    }

    public async Task<MockProcessResult> SendAsync(ProcessRequest request, CancellationToken cancellationToken = default)
    {
        var result = new MockProcessResult(
            request.InstanceId,
            Status: "Completed",
            Payload: $"Mock result for {request.InstanceId}",
            CompletedUtc: DateTimeOffset.UtcNow);

        await SendCallbackAsync(result, cancellationToken);

        return result;
    }

    public IReadOnlyList<ProcessRequest> DequeueScheduledDueRequests(TimeSpan delay, DateTimeOffset now)
    {
        var dueRequests = new List<ProcessRequest>();

        foreach (var entry in _requests)
        {
            if (now - entry.Value.EnqueuedUtc < delay)
            {
                continue;
            }

            if (_requests.TryRemove(entry.Key, out var cached))
            {
                dueRequests.Add(cached.Request);
            }
        }

        return dueRequests;
    }

    public IReadOnlyList<ProcessRequest> DequeueAllScheduled()
    {
        var all = new List<ProcessRequest>();

        foreach (var entry in _requests)
        {
            if (_requests.TryRemove(entry.Key, out var cached))
            {
                all.Add(cached.Request);
            }
        }

        return all;
    }

    public bool TryRemoveScheduled(string instanceId, out ProcessRequest request)
    {
        if (_requests.TryRemove(instanceId, out var cached))
        {
            request = cached.Request;
            return true;
        }

        request = null!;
        return false;
    }

    public bool TryGet(string instanceId, out ProcessRequest request)
    {
        if (_requests.TryGetValue(instanceId, out var cached))
        {
            request = cached.Request;
            return true;
        }

        request = null!;
        return false;
    }

    private async Task SendCallbackAsync(MockProcessResult result, CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient("callback-client");

        _logger.LogInformation("Sending scheduled callback for instance {InstanceId} to {CallbackUrl}.", result.InstanceId, $"tasks/{result.InstanceId}/callback");

        var response = await client.PostAsJsonAsync($"api/tasks/{result.InstanceId}/callback", result, cancellationToken);
        
        _logger.LogInformation("Scheduled callback response for instance {InstanceId}: {StatusCode}.", result.InstanceId, response.StatusCode);
    }
}

internal sealed record ScheduledProcessRequest(ProcessRequest Request, DateTimeOffset EnqueuedUtc);
