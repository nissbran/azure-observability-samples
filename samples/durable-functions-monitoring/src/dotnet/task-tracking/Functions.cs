using System;
using System.Diagnostics;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask;
using Microsoft.DurableTask.Client;
using Microsoft.DurableTask.Entities;
using Microsoft.Extensions.Logging;

namespace TaskTracking;

public static class ProcessSteps
{
    public const string TaskProcessOrchestrator = "StartProcessTaskOrchestrator";
    public const string SendExternalRequest = "SendExternalRequest";
    public const string StoreResultToBlob = "StoreResultToBlob";
    public const string NotifyUserOfCompletion = "NotifyUserOfCompletion";
    public const string PersistAuditLog = "PersistAuditLog";
    
    public const string WaitForUploadEvent = "WaitForUpload";
}

public static class OrchestratorFunctions
{
    [Function(ProcessSteps.TaskProcessOrchestrator)]
    public static async Task<TaskFinalInformation> StartProcessTaskOrchestrator([OrchestrationTrigger] TaskOrchestrationContext context)
    {
        var logger = context.CreateReplaySafeLogger(ProcessSteps.TaskProcessOrchestrator);

        logger.LogDebug("Starting process task orchestration with ID: {InstanceId}", context.InstanceId);

        var input = context.GetInput<TaskInitializationInformation>();
        var auditId = new EntityInstanceId(nameof(TaskAudit), $"audit-{context.InstanceId}");

        await context.Entities.SignalEntityAsync(auditId, nameof(TaskAudit.SetRequested), new SetRequesterOperation
        {
            RequestedAt = context.CurrentUtcDateTime,
            Requester = input.UserId
        });

        await PersistAuditLogAsync(context, "Started", input.UserId);
        
        var externalRequest = new ProcessTaskExternalRequest
        {
            TaskId = context.InstanceId,
            DocumentType = "Report"
        };
        
        context.SetCustomStatus(new
        {
            Status = "Sending external request."
        });

        await context.CallActivityAsync(ProcessSteps.SendExternalRequest, externalRequest);
        context.SetCustomStatus(new
        {
            Status = "Waiting for upload."
        });

        await context.Entities.SignalEntityAsync(auditId, nameof(TaskAudit.SetToWaiting), context.CurrentUtcDateTime);
        await PersistAuditLogAsync(context, "Waiting");
        
        var callbackPayload = await context.WaitForExternalEvent<ProcessTaskCallbackResult>(ProcessSteps.WaitForUploadEvent);
        context.SetCustomStatus(new
        {
            Status = "Processing callback."
        }); 

        var result = new ProcessTaskResult
        {
            TaskId = context.InstanceId,
            Result = callbackPayload.Status,
            UserId = input.UserId,
            CompletedUtc = context.CurrentUtcDateTime
        };
 
        await context.CallActivityAsync(ProcessSteps.StoreResultToBlob, result);
        context.SetCustomStatus(new
        {
            Status = "Notifying user of completion."
        });
        
        await context.Entities.SignalEntityAsync(auditId, nameof(TaskAudit.SetStored), context.CurrentUtcDateTime);
        await PersistAuditLogAsync(context, "Stored");

        await context.CallActivityAsync(ProcessSteps.NotifyUserOfCompletion, result);
        
        await context.Entities.SignalEntityAsync(auditId, nameof(TaskAudit.SetNotified), context.CurrentUtcDateTime);
        await PersistAuditLogAsync(context, "Notified");
        
        await context.Entities.SignalEntityAsync(auditId, nameof(TaskAudit.MarkCompleted), context.CurrentUtcDateTime);
        await PersistAuditLogAsync(context, "Completed");
        
        var finalAudit = await context.Entities.CallEntityAsync<TaskAuditState>(auditId, nameof(TaskAudit.GetState));

        return new TaskFinalInformation
        {
            CompletedAt = finalAudit.CompletedAt.GetValueOrDefault()
        };
    }

    private static Task PersistAuditLogAsync(TaskOrchestrationContext context, string status, string? requester = null)
    {
        var timestamp = new DateTimeOffset(context.CurrentUtcDateTime, TimeSpan.Zero);
        var request = new AuditLogRequest
        {
            InstanceId = context.InstanceId,
            Requester = requester,
            Status = status,
            Timestamp = timestamp
        };

        return context.CallActivityAsync(ProcessSteps.PersistAuditLog, request);
    }
}

public class ApiFunctions
{
    [Function(nameof(AddProcessTask))]
    public async Task<IActionResult> AddProcessTask([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "tasks")] HttpRequest req,
        [Microsoft.Azure.Functions.Worker.Http.FromBody] ProcessTaskStartRequest request,
        [DurableClient] DurableTaskClient client,
        FunctionContext executionContext)
    {
        if (request == null)
        {
            return new BadRequestObjectResult("Request body is required.");
        }

        var taskInitInfo = new TaskInitializationInformation
        {
            DocumentType = "ProcessTask",
            UserId = "Anonymous",
        };

        var instanceId = await client.ScheduleNewOrchestrationInstanceAsync(ProcessSteps.TaskProcessOrchestrator, taskInitInfo);

        return new AcceptedResult($"/api/tasks/{instanceId}", new
        {
            InstanceId = instanceId
        });
    }

    [Function(nameof(GetOrchestrationStatus))]
    public async Task<IActionResult> GetOrchestrationStatus([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "tasks/{taskId}")] HttpRequest req,
        [DurableClient] DurableTaskClient client,
        string taskId,
        FunctionContext executionContext)
    {
        var task = await client.GetInstanceAsync(taskId);

        if (task == null)
        {
            return new NotFoundResult();
        }

        return new OkObjectResult(task);
    }

    [Function(nameof(ProcessTaskCallback))]
    public async Task<IActionResult> ProcessTaskCallback([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "tasks/{taskId}/callback")] HttpRequest req,
        [DurableClient] DurableTaskClient client,
        [Microsoft.Azure.Functions.Worker.Http.FromBody] ProcessTaskCallbackResult callbackRequest,
        string taskId,
        FunctionContext executionContext)
    {
        await client.RaiseEventAsync(taskId, ProcessSteps.WaitForUploadEvent, callbackRequest);

        return new AcceptedResult();
    }
    
}
public class ProcessTaskActivities
{
    public class ProcessRequest
    {
        public string InstanceId { get; set; } = string.Empty;
        public string DocumentType { get; set; } = string.Empty;
    }
    private readonly HttpClient _client;
    private readonly BlobContainerClient _blobContainerClient;
    
    public ProcessTaskActivities(IHttpClientFactory httpClientFactory, BlobContainerClient blobContainerClient)
    {
        _client = httpClientFactory.CreateClient("ExternalSystem");
        _blobContainerClient = blobContainerClient;
    }

    [Function(ProcessSteps.SendExternalRequest)]
    public async Task SendExternalRequest([ActivityTrigger] ProcessTaskExternalRequest request,
        FunctionContext executionContext)
    {
        var logger = executionContext.GetLogger(ProcessSteps.SendExternalRequest);

        var result = await _client.PostAsJsonAsync("process", new ProcessRequest
        {
            InstanceId = request.TaskId,
            DocumentType = request.DocumentType
        });

        logger.LogDebug("Sent external request for task '{TaskId}'. Response status: {StatusCode}", request.TaskId, result.StatusCode);
    }

    [Function(ProcessSteps.StoreResultToBlob)]
    public async Task StoreResultToBlob([ActivityTrigger] ProcessTaskResult result,
        FunctionContext executionContext)
    {
        var logger = executionContext.GetLogger(ProcessSteps.StoreResultToBlob);
        logger.LogDebug("Storing result for task '{TaskId}' with status '{Status}'", result.TaskId, result.Result);
        var blobClient = _blobContainerClient.GetBlobClient($"{result.TaskId}.json");
        await blobClient.UploadAsync(BinaryData.FromString(result.Result));
    }
    
    [Function(ProcessSteps.NotifyUserOfCompletion)]
    public async Task NotifyUserOfCompletion([ActivityTrigger] ProcessTaskResult result,
        FunctionContext executionContext)
    {
        var logger = executionContext.GetLogger(ProcessSteps.NotifyUserOfCompletion);
        logger.LogDebug("Notifying user of completion for task '{TaskId}' with status '{Status}'", result.TaskId, result.Result);
    
        await Task.CompletedTask;
    }
}


public class ProcessTaskStartRequest
{
    public string DocumentType { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
}

public class TaskInitializationInformation
{
    public string DocumentType { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
}

public class TaskFinalInformation
{
    public DateTimeOffset CompletedAt { get; set; }
}

public class ProcessTaskExternalRequest
{
    public string TaskId { get; init; } = string.Empty;
    public string DocumentType { get; init; } = string.Empty;
}

public class ProcessTaskResult
{
    public string TaskId { get; init; } = string.Empty;
    public string Result { get; init; } = string.Empty;
    public string UserId { get; init; } = string.Empty;
    public DateTime CompletedUtc { get; init; }
}

public class ProcessTaskCallbackResult
{
    public string InstanceId { get; init; } = string.Empty;
    public string Status { get; init; } = string.Empty;
    public DateTimeOffset CompletedUtc { get; init; }
}

public static class DurableFunctionsPatterns
{

    [Function("Monitoring")]
    public static async Task<string> Monitoring(
        [OrchestrationTrigger] TaskOrchestrationContext context)
    {
        int pollingInterval = 10;
        DateTime expiryTime = context.CurrentUtcDateTime.AddMinutes(2);
        int numTries = 1;
        string completedString = "Completed";

        while (context.CurrentUtcDateTime < expiryTime)
        {
            context.SetCustomStatus($"Tried getting the status {numTries} times.");
            var jobStatus = await context.CallActivityAsync<string>(nameof(GetStatus), numTries);
            if (jobStatus == completedString)
            {
                return completedString;
            }

            var nextCheck = context.CurrentUtcDateTime.AddSeconds(pollingInterval);
            await context.CreateTimer(nextCheck, CancellationToken.None);
            numTries++;
        }

        return "";
    }

    // Send an event called "Approval Event"
    [Function("HumanInteraction")]
    public static async Task<string> HumanInteraction(
        [OrchestrationTrigger] TaskOrchestrationContext context)
    {
        using (var timeoutCts = new CancellationTokenSource())
        {
            DateTime dueTime = context.CurrentUtcDateTime.AddMinutes(5);
            Task durableTimeout = context.CreateTimer(dueTime, timeoutCts.Token);

            Task<bool> approvalEvent = context.WaitForExternalEvent<bool>("ApprovalEvent");
            if (approvalEvent == await Task.WhenAny(approvalEvent, durableTimeout))
            {
                timeoutCts.Cancel();
                return "Process approval";
            }
            else
            {
                return "escalate";
            }
        }
    }

    [Function(nameof(GetStatus))]
    public static string GetStatus([ActivityTrigger] int numTries,
        FunctionContext executionContext)
    {
        if (numTries == 3)
        {
            return "Completed";
        }

        return "In Progress";
    }
}

public class Counter : TaskEntity<int>
{
    readonly ILogger logger;

    public Counter(ILogger<Counter> logger)
    {
        this.logger = logger;
    }

    public void Add(int amount) => this.State += amount;

    public void Reset() => this.State = 0;

    public int Get() => this.State;
    
    protected override int InitializeState(TaskEntityOperation operation)
    {
        // This is called when state is null, giving a chance to customize first-access of entity.
        return 10;
    }

    [Function(nameof(Counter))]
    public Task RunEntityAsync([EntityTrigger] TaskEntityDispatcher dispatcher)
    {
        return dispatcher.DispatchAsync(this);
    }
}

public static class CounterOrchestrationFunctions
{
    [Function("CounterOrchestration")]
    public static async Task Run([OrchestrationTrigger] TaskOrchestrationContext context)
    {
        var currentActivity = Activity.Current;
        var entityId = new EntityInstanceId(nameof(Counter), "myCounter");

        // Two-way call to the entity which returns a value - awaits the response
        int currentValue = await context.Entities.CallEntityAsync<int>(entityId, "Get");

        if (currentValue < 10)
        {
            // One-way signal to the entity which updates the value - does not await a response
            await context.Entities.SignalEntityAsync(entityId, "Add", 1);
        }
    }
}

public class AuditLogActivities(TaskAuditDbContext dbContext)
{
    [Function(ProcessSteps.PersistAuditLog)]
    public async Task PersistAuditLog([ActivityTrigger] AuditLogRequest request, FunctionContext executionContext)
    {
        var task = await dbContext.Tasks.FindAsync(request.InstanceId);
        if (task == null)
        {
            task = new OrchestrationTask
            {
                InstanceId = request.InstanceId,
                Requester = request.Requester,
                CreatedAt = request.Timestamp,
                LastUpdatedAt = request.Timestamp
            };
            dbContext.Tasks.Add(task);
        }
        else
        {
            task.LastUpdatedAt = request.Timestamp;
        }

        dbContext.AuditLogs.Add(new OrchestrationAuditLog
        {
            InstanceId = request.InstanceId,
            Status = request.Status,
            Timestamp = request.Timestamp
        });
        await dbContext.SaveChangesAsync();
    }
}
