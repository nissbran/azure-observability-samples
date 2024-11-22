using System.IdentityModel.Tokens.Jwt;
using Asp.Versioning;
using Asp.Versioning.ApiExplorer;
using BookingApi.Data;
using BookingApi.Modules.Booking;
using BookingApi.Telemetry;
using Scalar.AspNetCore;
using Serilog;

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
        builder.Services.AddAuthorization(options => { options.AddPolicy("ReadBookings", p => p.RequireRole("Read.Bookings")); });

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
        builder.Services.AddEndpointsApiExplorer();
        
        foreach (var version in ApiVersions.AllActive)
        {
            builder.Services.AddOpenApi(version.ToString(), options =>
            {
                options.AddDocumentTransformer((document, context, cancellationToken) =>
                {
                    var versionedDescriptionProvider = context.ApplicationServices.GetService<IApiVersionDescriptionProvider>();
                    var apiDescription = versionedDescriptionProvider?.ApiVersionDescriptions
                        .SingleOrDefault(description => description.GroupName == context.DocumentName);
                    if (apiDescription is null)
                    {
                        return Task.CompletedTask;
                    }

                    document.Info.Version = apiDescription.ApiVersion.ToString();
                    document.Info.Title = "Booking API " + apiDescription.ApiVersion;
                    //document.Info.Description = //BuildDescription(apiDescription, description);
                    return Task.CompletedTask;
                });
                // Clear out the default servers so we can fallback to
                // whatever ports have been allocated for the service by Aspire
                options.AddDocumentTransformer((document, context, cancellationToken) =>
                {
                    document.Servers = [];
                    return Task.CompletedTask;
                });
            });
        }

        builder.AddSqlServerDbContext<BookingDbContext>("booking-db");

        return builder.Build();
    }

    public static WebApplication ConfigurePipeline(this WebApplication app)
    {
        app.UseHealthChecks("/healthz");
        app.UseAuthorization();

        app.MapOpenApi();

        if (app.Environment.IsDevelopment())
        {
            app.MapScalarApiReference(options =>
            {
                // Disable default fonts to avoid download unnecessary fonts
                options.DefaultFonts = false;
            });
            app.MapGet("/", () => Results.Redirect($"/scalar/{ApiVersions.Default}")).ExcludeFromDescription();
        }

        if (ObservabilityConfiguration.IsSerilogConfigured)
        {
            app.UseSerilogRequestLogging();
        }
        
        BookingModule.MapRoutes(app);

        return app;
    }
}