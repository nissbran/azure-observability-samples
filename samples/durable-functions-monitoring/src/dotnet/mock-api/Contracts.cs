using System.Diagnostics;

namespace ExternalSystemMockApi;

public class ProcessRequest
{
    public string InstanceId { get; set; } = string.Empty;
    public string DocumentType { get; set; } = string.Empty;
    public ActivityTraceId? TraceId { get; set; }
}