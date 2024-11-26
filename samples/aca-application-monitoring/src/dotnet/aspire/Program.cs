using Microsoft.Extensions.Configuration;

var builder = DistributedApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.local.json", true);

var sql = builder.AddAzureSqlServer("sql")
    .RunAsContainer(resourceBuilder => resourceBuilder.WithLifetime(ContainerLifetime.Persistent));
var creditDb = sql.AddDatabase("credit-db");
var bookingDb = sql.AddDatabase("booking-db");

IResourceBuilder<IResourceWithConnectionString> serviceBus;

if (builder.ExecutionContext.IsPublishMode)
{
    serviceBus = builder.AddAzureServiceBus("messaging");
}
else
{
    // var sqlPassword = ParameterResourceBuilderExtensions.CreateDefaultPasswordParameter(builder, "sqledge-password", minLower: 1, minUpper: 1, minNumeric: 1);
    // var sqlEdge = builder.AddContainer("sqledge", "mcr.microsoft.com/azure-sql-edge", "latest")
    //     .WithEnvironment("MSSQL_SA_PASSWORD", sqlPassword.Value)
    //     .WithEnvironment("ACCEPT_EULA", "Y");
    
    var sqlPasswordParameter = sql.Resource.ConnectionStringExpression.ValueProviders
        .FirstOrDefault(provider => provider is ParameterResource { Name: "sql-password" }) as ParameterResource;

    var sbEmulatorConfigAbsolutePath = Path.GetFullPath("ServiceBusConfig.json");

    builder.AddContainer("servicebusemulator", "mcr.microsoft.com/azure-messaging/servicebus-emulator", "latest")
        .WithBindMount(sbEmulatorConfigAbsolutePath, "/ServiceBus_Emulator/ConfigFiles/Config.json")
        .WithEnvironment("SQL_SERVER", "sql")
        .WithEnvironment("MSSQL_SA_PASSWORD", sqlPasswordParameter?.Value)
        .WithEnvironment("ACCEPT_EULA", "Y")
        .WithHttpEndpoint(5672, 5672);
        //.WaitFor(sql);
    
    serviceBus = builder.AddConnectionString("messaging");
}

var dbSetup = builder.AddProject<Projects.DbSetup>("db-setup")
    .WithReference(creditDb)
    .WithReference(bookingDb)
    .WaitFor(sql);

builder.AddProject<Projects.CreditApi>("credit-api")
    .WithReference(serviceBus)
    .WithReference(creditDb)
    .WaitForCompletion(dbSetup)
    .PublishAsAzureContainerApp((infrastructure, app) => { });

builder.AddProject<Projects.BookingProcessor>("booking-processor")
    .WithReference(serviceBus)
    .WithReference(bookingDb)
    .WaitForCompletion(dbSetup);

builder.AddProject<Projects.BookingApi>("booking-api")
    .WithReference(bookingDb)
    .WaitForCompletion(dbSetup);

builder.Build().Run();