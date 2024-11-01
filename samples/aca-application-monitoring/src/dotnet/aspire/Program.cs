using Microsoft.Extensions.Configuration;

var builder = DistributedApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.local.json", true);

var serviceBus = builder.ExecutionContext.IsPublishMode
       ? builder.AddAzureServiceBus("messaging")
       : builder.AddConnectionString("messaging");
var sql = builder.AddSqlServer("sql");
var creditDb = sql.AddDatabase("credit-db");
var bookingDb = sql.AddDatabase("booking-db");

builder.AddProject<Projects.CreditApi>("credit-api")
       .WithReference(serviceBus)
       .WithReference(creditDb);
       
builder.AddProject<Projects.BookingProcessor>("booking-processor")
       .WithReference(serviceBus)
       .WithReference(bookingDb);

builder.AddProject<Projects.BookingApi>("booking-api")
       .WithReference(bookingDb);

builder.AddProject<Projects.DbSetup>("db-setup")
       .WithReference(creditDb)
       .WithReference(bookingDb);

builder.Build().Run();