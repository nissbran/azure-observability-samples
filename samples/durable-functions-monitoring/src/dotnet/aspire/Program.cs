var builder = DistributedApplication.CreateBuilder(args);

var storage = builder.AddAzureStorage("storage").RunAsEmulator();
var fileStorage = storage.AddBlobContainer("file-storage");

// var scheduler = builder.AddDurableTaskScheduler("scheduler").RunAsEmulator();
// var taskHub = scheduler.AddTaskHub("taskhub");

var sql = builder.AddAzureSqlServer("sql")
    .RunAsContainer(container =>
    {
        container.WithLifetime(ContainerLifetime.Persistent);
    });
var auditDb = sql.AddDatabase("task-audit-db");
//var taskHub = sql.AddDatabase("task-tracking-hub");

var dbSetup = builder.AddProject<Projects.DbSetup>("db-setup")
    .WithReference(auditDb)
    .WaitFor(sql);
var mockApi = builder.AddProject<Projects.ExternalSystemMockApi>("ExternalSystemMockApi");

var taskTrackingFunctions = builder.AddAzureFunctionsProject<Projects.TaskTracking>("TaskTracking")
    .WithHostStorage(storage)
    //.WithReference(taskHub)
    .WithReference(auditDb)
    .WithReference(mockApi)
    .WithReference(fileStorage)
    .WaitFor(storage)
    .WaitForCompletion(dbSetup)
    .WithExternalHttpEndpoints();

builder.Build().Run();