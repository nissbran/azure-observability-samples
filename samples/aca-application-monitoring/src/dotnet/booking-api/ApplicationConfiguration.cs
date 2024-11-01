using System.IdentityModel.Tokens.Jwt;
using Asp.Versioning;
using BookingApi.Data;
using BookingApi.Modules.Booking;
using BookingApi.Telemetry;
using Microsoft.Extensions.Options;
using Serilog;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace BookingApi;

internal static class ApplicationConfiguration
{
    public static WebApplication ConfigureServices(this WebApplicationBuilder builder)
    {
        builder.Services.ConfigureHttpClientDefaults(http =>
        {
            // Turn on resilience by default
            http.AddStandardResilienceHandler();

            // Turn on service discovery by default
            http.AddServiceDiscovery();
        });
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddTransient<IConfigureOptions<SwaggerGenOptions>, ConfigureSwaggerOptions>();
        builder.Services.AddSwaggerGen( options => options.OperationFilter<SwaggerDefaultValues>() );
        builder.Services.AddHealthChecks();

        // This is required to prevent the default mapping of claims to roles
        // By default the JwtSecurityTokenHandler will map claims to names like http://schemas.microsoft.com/ws/2008/06/identity/claims/role
        JwtSecurityTokenHandler.DefaultMapInboundClaims = false;
        
        builder.Services.AddAuthentication().AddJwtBearer(options =>
        {
            options.Authority = builder.Configuration["Authority"];
            options.Audience = builder.Configuration["Audience"];
            options.TokenValidationParameters.RoleClaimType = "roles";
        });
        builder.Services.AddAuthorization(options =>
        {
            options.AddPolicy("ReadBookings", p => p.RequireRole("Read.Bookings"));
        });

        builder.Services.AddApiVersioning(options =>
        {
            options.ReportApiVersions = true;
            options.AssumeDefaultVersionWhenUnspecified = true;
            options.DefaultApiVersion = ApiVersions.Default;
            options.ApiVersionReader = new QueryStringApiVersionReader("api-version");
        })
        .AddApiExplorer(
            options =>
            {
                options.GroupNameFormat = "GG";
                options.SubstituteApiVersionInUrl = true;
            });
        
        builder.AddSqlServerDbContext<BookingDbContext>("booking-db");

        return builder.Build();
    }

    public static WebApplication ConfigurePipeline(this WebApplication app)
    {
        app.UseHealthChecks("/healthz");
        app.UseAuthorization();
        BookingModule.MapRoutes(app);
        
        app.UseSwagger();
        if (app.Environment.IsDevelopment())
        {
            app.UseSwaggerUI(
                options =>
                {
                    var descriptions = app.DescribeApiVersions();

                    // build a swagger endpoint for each discovered API version
                    foreach ( var description in descriptions )
                    {
                        var url = $"/swagger/{description.GroupName}/swagger.json";
                        var name = description.GroupName.ToUpperInvariant();
                        options.SwaggerEndpoint( url, name );
                    }
                });
        }
        
        if (ObservabilityConfiguration.IsSerilogConfigured)
        {
            app.UseSerilogRequestLogging();
        }
        
        return app;
    }
}