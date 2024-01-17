using Serilog;
using Serilog.Formatting.Json;

Console.WriteLine("Now generate some logs...");

Log.Logger = new LoggerConfiguration()
    .WriteTo.File(new JsonFormatter(renderMessage:true), @"C:\Logs\testlog.log")
    .CreateLogger();


for (int i = 0; i < 10; i++)
{
    await Task.Delay(1000);
    Log.Information("Hello, Serilog! {i}", i);
}

Log.Error("This is an error");

Log.CloseAndFlush();
