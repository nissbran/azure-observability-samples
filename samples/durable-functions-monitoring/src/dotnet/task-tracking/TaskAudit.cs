using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.DurableTask.Entities;

namespace TaskTracking;

public class TaskAudit : TaskEntity<TaskAuditState>
{
    public void SetRequested(SetRequesterOperation operation)
    {
        State.Requester = operation.Requester;
        State.RequestedAt = operation.RequestedAt;
        State.Status = "Started";
        State.AuditRows.Add(new AuditRow
        {
            Timestamp = operation.RequestedAt,
            Status = "Started",
        });
    }

    public void SetToWaiting()
    {
        State.Status = "Waiting";
        State.AuditRows.Add(new AuditRow
        {
            Timestamp = DateTime.UtcNow,
            Status = "Waiting",
        });
    }

    public void SetNotified()
    {
        State.Status = "Notified";
        State.AuditRows.Add(new AuditRow
        {
            Timestamp = DateTime.UtcNow,
            Status = "Notified",
        });
    }
    
    public void SetStored()
    {
        State.Status = "Stored";
        State.AuditRows.Add(new AuditRow
        {
            Timestamp = DateTime.UtcNow,
            Status = "Stored",
        });
    }

    public void MarkCompleted(DateTimeOffset completedAt)
    {
        State.CompletedAt = completedAt;
        State.Status = "Completed";
        State.AuditRows.Add(new AuditRow
        {
            Timestamp = completedAt,
            Status = "Completed",
        });
    }

    public TaskAuditState GetState()
    {
        return State;
    }
    
    [Function(nameof(TaskAudit))]
    public Task RunEntityAsync([EntityTrigger] TaskEntityDispatcher dispatcher)
    {
        return dispatcher.DispatchAsync(this);
    }

    protected override TaskAuditState InitializeState(TaskEntityOperation operation)
    {
        return new TaskAuditState
        {
            Status = "Initialized",
            AuditRows = new List<AuditRow>()
            {
                new AuditRow
                {
                    Timestamp = DateTimeOffset.UtcNow,
                    Status = "Initialized"
                }
            }
        };
    }
}

public class TaskAuditState
{
    public string Requester { get; set; } = string.Empty;
    public DateTimeOffset RequestedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
    public string Status { get; set; } = string.Empty;

    public List<AuditRow> AuditRows { get; set; }
}

public class AuditRow
{
    public DateTimeOffset Timestamp { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class SetRequesterOperation
{
    public string Requester { get; init; }
    public DateTimeOffset RequestedAt { get; init; }
}