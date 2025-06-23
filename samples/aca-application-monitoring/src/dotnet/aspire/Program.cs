using Microsoft.Extensions.Configuration;

var builder = DistributedApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.local.json", true);

var sql = builder.AddAzureSqlServer("sql")
    .RunAsContainer(container =>
    {
        container.WithLifetime(ContainerLifetime.Persistent);
    });

var creditDb = sql.AddDatabase("credit-db");
var bookingDb = sql.AddDatabase("booking-db");

var serviceBus = builder.AddAzureServiceBus("messaging")
    .RunAsEmulator(emulator =>
    {
        emulator.WithConfigurationFile(
            path: "./ServiceBusConfig.json");
    });

var dbSetup = builder.AddProject<Projects.DbSetup>("db-setup")
    .WithReference(creditDb)
    .WithReference(bookingDb)
    .WaitFor(sql);

builder.AddProject<Projects.CreditApi>("credit-api")
    .WithReference(serviceBus)
    .WithReference(creditDb)
    .WaitForCompletion(dbSetup);

builder.AddProject<Projects.BookingProcessor>("booking-processor")
    .WithReference(serviceBus)
    .WithReference(bookingDb)
    .WaitForCompletion(dbSetup)
    .WaitFor(serviceBus);

builder.AddProject<Projects.BookingApi>("booking-api")
    .WithReference(bookingDb)
    .WaitForCompletion(dbSetup);

builder.Build().Run();