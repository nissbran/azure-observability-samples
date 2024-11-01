using System.Diagnostics;
using BookingApi.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace BookingApi.Modules.Booking;

public static class BookingModule
{
    public static void MapRoutes(IEndpointRouteBuilder app)
    {
        var bookings = app.NewVersionedApi("Bookings");
        var bookingsV1 = bookings.MapGroup("bookings").HasApiVersion(ApiVersions.V1);

        bookingsV1.MapGet("{id}", GetCreditBookingsV1)
            .Produces<GetCreditBookingResponseV1>();
        
        var bookingsV2 = bookings.MapGroup("bookings").HasApiVersion(ApiVersions.V2);
        bookingsV2.MapGet("{id}", GetCreditBookingsV2)
            .Produces<GetCreditBookingResponseV2>()
            .RequireAuthorization("ReadBookings");;
    }

    private static async Task<IResult> GetCreditBookingsV1(string id, BookingDbContext dbContext)
    {
        if (!Guid.TryParse(id, out var creditId)) 
            return TypedResults.BadRequest();
        
        Activity.Current?.AddTag("creditId", creditId);
            
        var bookings = await dbContext.BookingMonths
            .Where(b => b.CreditId == creditId)
            .Include(b => b.Bookings)
            .AsNoTracking()
            .ToListAsync();

        if (bookings.IsNullOrEmpty())
        {
            return TypedResults.NotFound();
        }
            
        return TypedResults.Ok(new GetCreditBookingResponseV1(bookings));
    }
    
    private static async Task<IResult> GetCreditBookingsV2(Guid id, BookingDbContext dbContext)
    {
        Activity.Current?.AddTag("creditId", id);
            
        var bookings = await dbContext.BookingMonths
            .Where(b => b.CreditId == id)
            .AsNoTracking()
            .ToListAsync();

        if (bookings.IsNullOrEmpty())
        {
            return TypedResults.NotFound();
        }
            
        return TypedResults.Ok(new GetCreditBookingResponseV2(bookings));
    }
}