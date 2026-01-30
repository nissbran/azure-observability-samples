var builder = DistributedApplication.CreateBuilder(args);

var storage = builder.AddAzureStorage("storage").RunAsEmulator();
var fileStorage = storage.AddBlobContainer("file-storage");

// var scheduler = builder.AddDurableTaskScheduler("scheduler").RunAsEmulator();

// var taskHub = scheduler.AddTaskHub("taskhub");
// var sql = builder.AddAzureSqlServer("sql")
//     .RunAsContainer(container =>
//     {
//         container.WithLifetime(ContainerLifetime.Persistent);
//     });

//var taskHub = sql.AddDatabase("task-tracking-hub");

var mockApi = builder.AddProject<Projects.ExternalSystemMockApi>("ExternalSystemMockApi");

var taskTrackingFunctions = builder.AddAzureFunctionsProject<Projects.TaskTracking>("TaskTracking")
    .WithHostStorage(storage)
    //.WithReference(taskHub)
    .WithReference(mockApi)
    .WithReference(fileStorage)
    .WaitFor(storage)
    .WithExternalHttpEndpoints();

builder.Build().Run();