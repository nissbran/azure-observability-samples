using Asp.Versioning;

namespace BookingApi;

public static class ApiVersions
{
    public static ApiVersion Default => V1;
    
    public static readonly ApiVersion V1 = new(new DateOnly(2024, 10, 30));
    public static readonly ApiVersion V2 = new(new DateOnly(2024, 11, 4));
    
    public static readonly List<ApiVersion> AllActive =
    [
        V1,
        V2
    ];
}