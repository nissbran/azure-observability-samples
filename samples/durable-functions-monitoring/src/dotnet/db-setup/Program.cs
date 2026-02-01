using DbSetup.Telemetry;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using TaskTracking;

var builder = Host.CreateApplicationBuilder(args);

builder.Configuration.AddJsonFile("appsettings.local.json", true);

builder.AddSqlServerDbContext<TaskAuditDbContext>("task-audit-db");
builder.ConfigureTelemetry();

using var app = builder.Build();
using var scope = app.Services.CreateScope();
using var taskAuditDb = scope.ServiceProvider.GetRequiredService<TaskAuditDbContext>();

foreach (var db in new DbContext[] { taskAuditDb })
{
    var created = await db.Database.EnsureCreatedAsync();
    if (created)
    {
        Log.Information("Database {Database} created", db.Database.GetDbConnection().Database);
    }
}