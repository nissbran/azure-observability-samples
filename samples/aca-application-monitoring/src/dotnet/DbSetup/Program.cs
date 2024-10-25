using BookingProcessor.Data;
using CreditApi.Data;
using DbSetup.Telemetry;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;

var builder = Host.CreateApplicationBuilder(args);

builder.Configuration.AddJsonFile("appsettings.local.json", true);

builder.AddSqlServerDbContext<CreditDbContext>("credit-db");
builder.AddSqlServerDbContext<BookingDbContext>("booking-db");
builder.ConfigureTelemetry();


using var app = builder.Build();
using var scope = app.Services.CreateScope();
using var creditDb = scope.ServiceProvider.GetRequiredService<CreditDbContext>();
using var bookingDb = scope.ServiceProvider.GetRequiredService<BookingDbContext>();

foreach (var db in new DbContext[] { creditDb, bookingDb })
{
    var created = await db.Database.EnsureCreatedAsync();
    if (created)
    {
        Log.Information("Database {Database} created", db.Database.GetDbConnection().Database);
    }
}